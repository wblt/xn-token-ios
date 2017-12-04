//
//  TLTransactionVC.m
//  Coin
//
//  Created by  tianlei on 2017/11/06.
//  Copyright © 2017年  tianlei. All rights reserved.
//

#import "TLTransactionVC.h"
#import "TLUIHeader.h"

#import "UITabBar+Badge.h"

#import "TradeTableView.h"
#import "CoinChangeView.h"
#import "TLBannerView.h"
#import "PublishTipView.h"
#import "TopLabelUtil.h"
#import "FilterView.h"

#import "BannerModel.h"
#import "UpdateModel.h"

#import "WebVC.h"
#import "PublishBuyVC.h"
#import "PublishSellVC.h"
#import "TradeBuyVC.h"
#import "TradeSellVC.h"
#import "SearchVC.h"
#import "TLNavigationController.h"
#import "TLUserLoginVC.h"

@interface TLTransactionVC ()<SegmentDelegate, RefreshDelegate>

//货币切换
@property (nonatomic, strong) CoinChangeView *changeView;
//筛选
@property (nonatomic, strong) FilterView *filterPicker;
//
@property (nonatomic, strong) TLPageDataHelper *helper;
//暂无交易
@property (nonatomic, strong) UIView *placeHolderView;
//切换
@property (nonatomic, strong) TopLabelUtil *labelUnil;
//图片
@property (nonatomic,strong) NSMutableArray *bannerPics;
//tableview
@property (nonatomic, strong) TradeTableView *tableView;
//广告列表
@property (nonatomic, strong) NSArray <AdvertiseModel *>*advertises;
//发布
@property (nonatomic, strong) UIButton *publishBtn;
//发布界面
@property (nonatomic, strong) PublishTipView *tipView;
//banner
@property (nonatomic, strong) TLBannerView *bannerView;
//
@property (nonatomic,strong) NSMutableArray <BannerModel *>*bannerRoom;
//交易方式(买币和卖币)
@property (nonatomic, copy) NSString *tradeType;

@end

@implementation TLTransactionVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self navBarUI];
    
    [self setUpUI];
    //获取广告
    [self requestAdvetiseList];
    //添加通知
    [self addNotification];
    //强制更新
    [self configUpdate];

}

#pragma mark - Init

-(TopLabelUtil *)labelUnil {
    
    if (!_labelUnil) {
        
        _labelUnil = [[TopLabelUtil alloc]initWithFrame:CGRectMake(kScreenWidth/2 - 120, 25, 240, 44)];
        _labelUnil.delegate = self;
        _labelUnil.backgroundColor = [UIColor clearColor];
        _labelUnil.titleNormalColor = kTextColor;
        _labelUnil.titleSelectColor = kThemeColor;
        _labelUnil.titleFont = Font(17.0);
        _labelUnil.lineType = LineTypeTitleLength;

        _labelUnil.titleArray = @[@"买币",@"卖币"];
    }
    return _labelUnil;
}

- (void)navBarUI {
    
    //1.左边切换
    CoinChangeView *coinChangeView = [[CoinChangeView alloc] init];
    
    coinChangeView.title = @"ETH";
    
    [coinChangeView addTarget:self action:@selector(changeCoin) forControlEvents:UIControlEventTouchUpInside];
    
    self.changeView = coinChangeView;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:coinChangeView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        coinChangeView.title = @"ETH";

    });
    
    //2.右边搜索
    UIImage *searchImg = [UIImage imageNamed:@"交易_搜索"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:searchImg style:UIBarButtonItemStylePlain target:self action:@selector(search)];
    
    //3.中间切换
    
    self.navigationItem.titleView = self.labelUnil;


}

- (void)setUpUI {
    
    CoinWeakSelf;
    
    self.tradeType = @"1";
    
    [self initPlaceHolderView];
    
    self.tableView = [[TradeTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    
    self.tableView.placeHolderView = self.placeHolderView;
    
    self.tableView.refreshDelegate = self;
    
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    if (@available(iOS 11.0, *)) {
        
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
   //1.banner
    TLBannerView *bannerView = [[TLBannerView alloc] initWithFrame:CGRectMake(0, 0,SCREEN_WIDTH, kWidth(140))];
    
    bannerView.selected = ^(NSInteger index) {
        
        if (!(self.bannerRoom[index].url && self.bannerRoom[index].url.length > 0)) {
            return ;
        }
        
        WebVC *webVC = [WebVC new];
        
        webVC.url = weakSelf.bannerRoom[index].url;
        
        [weakSelf.navigationController pushViewController:webVC animated:YES];
        
    };
    
    self.bannerView = bannerView;
    
    self.tableView.tableHeaderView = bannerView;
    
    
   //2.发布
    self.publishBtn = [UIButton buttonWithImageName:@"发布"];
    
    [self.publishBtn addTarget:self action:@selector(clickPublish) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.publishBtn];
    [self.publishBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.mas_bottom).offset(-12);
        
    }];
    
    [self initTipView];
    
}

- (void)initPlaceHolderView {
    
    self.placeHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kSuperViewHeight - 40)];
    
    UIImageView *couponIV = [[UIImageView alloc] init];
    
    couponIV.image = kImage(@"暂无订单");
    
    [self.placeHolderView addSubview:couponIV];
    [couponIV mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.centerX.equalTo(@0);
        make.top.equalTo(@90);
        
    }];
    
    UILabel *textLbl = [UILabel labelWithBackgroundColor:kClearColor textColor:kTextColor2 font:14.0];
    
    textLbl.text = @"暂无交易";
    
    textLbl.textAlignment = NSTextAlignmentCenter;
    
    [self.placeHolderView addSubview:textLbl];
    [textLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(couponIV.mas_bottom).offset(20);
        make.centerX.equalTo(couponIV.mas_centerX);
        
    }];
}

- (void)initTipView {
    
    CoinWeakSelf;
    
    NSArray *titles = @[@"发布购买", @"发布卖出"];
    
    _tipView = [[PublishTipView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight) titles:titles];
    
    _tipView.publishBlock = ^(NSInteger index) {
        
        [weakSelf publishEventsWithIndex:index];

    };
}

- (FilterView *)filterPicker {
    
    if (!_filterPicker) {
        
        CoinWeakSelf;
        
        NSArray *textArr = @[@"ETH"];
        
//        NSArray *typeArr = @[@"", @"charge", @"withdraw", @"buy", @"sell"];
        
        _filterPicker = [[FilterView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
        
        _filterPicker.title = @"请选择货币类型";
        
        _filterPicker.selectBlock = ^(NSInteger index) {
            
            weakSelf.changeView.title = textArr[index];
            
//            weakSelf.helper.parameters[@"bizType"] = typeArr[index];
//
//            [weakSelf.tableView beginRefreshing];
        };
        
        _filterPicker.tagNames = textArr;
        
    }
    
    return _filterPicker;
}

- (void)addNotification{
    //发布购买/出售
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData:) name:kAdvertiseListRefresh object:nil];
    
    //信任/取消信任
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData) name:kTrustNotification object:nil];

}

#pragma mark - Events
- (void)changeCoin {
    
    [self.filterPicker show];
}

- (void)search {
    
    SearchVC *searchVC = [SearchVC new];
    
    [self.navigationController pushViewController:searchVC animated:YES];
}

- (void)clickPublish {
    
    [self.tipView show];
}

- (void)publishEventsWithIndex:(NSInteger)index {
 
    CoinWeakSelf;
    
    if (index == 0) {

        if (![TLUser user].isLogin) {
            
            TLUserLoginVC *loginVC = [[TLUserLoginVC alloc] init];
            
            TLNavigationController *nav = [[TLNavigationController alloc] initWithRootViewController:loginVC];
            
            loginVC.loginSuccess = ^(){
                
                [weakSelf publishEventsWithIndex:0];
            };
            
            [self presentViewController:nav animated:YES completion:nil];
            
            return;
        }
        
        PublishBuyVC *buyVC = [PublishBuyVC new];
        
        buyVC.type = PublishBuyPositionTypePublish;
        
        [self.navigationController pushViewController:buyVC animated:YES];
        
    } else if (index == 1) {
        
        if (![TLUser user].isLogin) {
            
            TLUserLoginVC *loginVC = [[TLUserLoginVC alloc] init];
            
            TLNavigationController *nav = [[TLNavigationController alloc] initWithRootViewController:loginVC];
            
            loginVC.loginSuccess = ^(){
                
                [weakSelf publishEventsWithIndex:1];
            };
            
            [self presentViewController:nav animated:YES completion:nil];
            
            return;
        }
        
        PublishSellVC *sellVC = [PublishSellVC new];
        
        sellVC.type = PublishSellPositionTypePublish;

        [self.navigationController pushViewController:sellVC animated:YES];
    }
}

- (void)refreshData:(NSNotification *)notification {
    
    NSInteger index = [notification.object integerValue];
    
    [self.labelUnil selectSortBarWithIndex:index];
    
}

- (void)refreshData {
    
    [self.tableView beginRefreshing];
}

#pragma mark - Data
- (void)getBanner {
    
    //广告图
    __weak typeof(self) weakSelf = self;
    
    TLNetworking *http = [TLNetworking new];
    //806052
    http.code = @"805806";
    http.parameters[@"type"] = @"2";
    http.parameters[@"location"] = @"trade";
    
    [http postWithSuccess:^(id responseObject) {
        
        weakSelf.bannerRoom = [BannerModel mj_objectArrayWithKeyValuesArray:responseObject[@"data"]];
        //组装数据
        weakSelf.bannerPics = [NSMutableArray arrayWithCapacity:weakSelf.bannerRoom.count];
        
        //取出图片
        [weakSelf.bannerRoom enumerateObjectsUsingBlock:^(BannerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [weakSelf.bannerPics addObject:[obj.pic convertImageUrl]];
        }];
        
        weakSelf.bannerView.imgUrls = weakSelf.bannerPics;
        
    } failure:^(NSError *error) {
        
    }];
    
}

- (void)requestAdvetiseList {
    
    CoinWeakSelf;
    
    TLPageDataHelper *helper = [TLPageDataHelper new];
    
    helper.code = @"625228";
    
    helper.start = 1;
    helper.limit = 20;
    
    helper.parameters[@"coin"] = @"ETH";
    helper.parameters[@"tradeType"] = self.tradeType;
    
    helper.tableView = self.tableView;
    
    self.helper = helper;
    
    [helper modelClass:[AdvertiseModel class]];
    
    [self.tableView addRefreshAction:^{
        
        //banner
        [weakSelf getBanner];
        
        [helper refresh:^(NSMutableArray *objs, BOOL stillHave) {
            
            weakSelf.advertises = objs;
            
            weakSelf.tableView.advertises = objs;

            [weakSelf.tableView reloadData_tl];

        } failure:^(NSError *error) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [weakSelf requestAdvetiseList];
            });
            
        }];
    }];
    
    [self.tableView beginRefreshing];

    [self.tableView addLoadMoreAction:^{
        
        [helper loadMore:^(NSMutableArray *objs, BOOL stillHave) {
            
            weakSelf.advertises = objs;
            
            weakSelf.tableView.advertises = objs;
            
            [weakSelf.tableView reloadData_tl];
            
        } failure:^(NSError *error) {
            
        }];
    }];
    
    [self.tableView endRefreshingWithNoMoreData_tl];
    
}

#pragma mark - Config
- (void)configUpdate {
    
    //1:iOS 2:安卓
    TLNetworking *http = [[TLNetworking alloc] init];
    
    http.code = @"625918";
    http.parameters[@"type"] = @"ios-c";
    
    [http postWithSuccess:^(id responseObject) {
        
        UpdateModel *update = [UpdateModel mj_objectWithKeyValues:responseObject[@"data"]];
        
        //获取当前版本号
        NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        
        if (![currentVersion isEqualToString:update.version]) {
            //1：强制，0：不强制
            if ([update.forceUpdate isEqualToString:@"0"]) {
                
                [TLAlert alertWithTitle:@"更新提醒" msg:update.note confirmMsg:@"立即升级" cancleMsg:@"稍后提醒" cancle:^(UIAlertAction *action) {
                    
                } confirm:^(UIAlertAction *action) {
                    
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[update.downloadUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
                    
                }];
                
            } else {
                
                [TLAlert alertWithTitle:@"更新提醒" message:update.note confirmMsg:@"立即升级" confirmAction:^{
                    
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[update.downloadUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]]];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        
                        exit(0);
                        
                    });
                }];
            }
        }
        
    } failure:^(NSError *error) {
        
    }];
    
}

#pragma mark - SegmentDelegate
-(void)segment:(TopLabelUtil *)segment didSelectIndex:(NSInteger)index {
    
    if (index == 1) {
        
        self.tradeType = @"1";
        
    }else {
        
        self.tradeType = @"0";

    }
    
    self.helper.parameters[@"tradeType"] = self.tradeType;

    [self.tableView beginRefreshing];
    
    [self.labelUnil dyDidScrollChangeTheTitleColorWithContentOfSet:(index-1)*kScreenWidth];

}

#pragma mark - RefreshDelegate

- (void)refreshTableView:(TLTableView *)refreshTableview didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.tradeType isEqualToString:@"1"]) {
        
        TradeBuyVC *buyVC = [TradeBuyVC new];
        
        buyVC.advertise = self.advertises[indexPath.row];
        
        buyVC.type = TradeBuyPositionTypeTrade;
        
        [self.navigationController pushViewController:buyVC animated:YES];
    } else {
        
        TradeSellVC *sellVC = [TradeSellVC new];
        
        sellVC.advertise = self.advertises[indexPath.row];
        
        sellVC.type = TradeBuyPositionTypeTrade;

        [self.navigationController pushViewController:sellVC animated:YES];
    }
    
    
}
@end
