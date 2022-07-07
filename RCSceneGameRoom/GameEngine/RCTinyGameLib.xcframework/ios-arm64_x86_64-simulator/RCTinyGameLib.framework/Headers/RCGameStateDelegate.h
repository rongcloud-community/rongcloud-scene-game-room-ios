#import <Foundation/Foundation.h>
#import "RCGameSettle.h"


typedef NS_ENUM(NSUInteger, RCGameState) {
    /**
     * idle 状态，游戏未开始，空闲状态
     */
    IDLE = 0,
    /**
     * loading 状态，所有玩家都准备好，队长点击了开始游戏按钮，等待加载游戏场景开始游戏
     */
    LOADING,
    /**
     * playing状态，游戏进行中状态
     */
    PLAYING
};

NS_ASSUME_NONNULL_BEGIN

@protocol RCGameStateDelegate <NSObject>

/**
 * 游戏加载完成
 */
- (void)onGameLoaded;

/**
 * 游戏销毁
 */
- (void)onGameDestroyed;

/**
 * 游戏内消息通知
 *
 * @param attributedMessage NSAttributedString类型的消息
 * @param rawMessage  原始未经过处理的String
 */
- (void)onReceivePublicMessage:(NSAttributedString *)attributedMessage rawMessage:(NSString *)rawMessage;

/**
 * 要命中的关键词
 * 例如你画我猜游戏，返回给用户的关键词
 *
 * @param keyword 关键词
 */
- (void)onKeywordToHit:(NSString *)keyword;

/**
 * 游戏状态改变
 *
 * @param gameState (idle 状态，游戏未开始，空闲状态）；
 *                  （loading 状态，所有玩家都准备好，队长点击了开始游戏按钮，等待加载游戏场景开始游戏）；
 *                  （playing状态，游戏进行中状态）
 */
- (void)onGameStateChanged:(RCGameState)gameState;

/**
 * 麦克风操作
 * @param isOpen 是否开启
 */
- (void)onMicrophoneChanged:(BOOL)isOpen;

/**
 * code过期，需要重新获取
 */
- (void)onExpireCode;


/**
 * 游戏结算结果
 * @param gameSettle 游戏结果模型对象
 */
- (void)onGameSettle:(RCGameSettle *)gameSettle;

/**
 * 游戏日志
 */
- (void)onGameLog:(NSString *)dataJson;


@end

NS_ASSUME_NONNULL_END
