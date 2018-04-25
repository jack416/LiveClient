/*
 * RequestJniConvert.h
 *
 *  Created on: 2017-5-25
 *      Author: Hunter.Mun
 *  Description Jni中间转换层
 */

#ifndef REQUESTJNICONVERT_H_
#define REQUESTJNICONVERT_H_

#include "GlobalFunc.h"

/*直播间状态转换*/
static const int HTTPErrorTypeArray[] = {
	    HTTP_LCC_ERR_SUCCESS,   		// 成功
	    HTTP_LCC_ERR_FAIL, 				// 服务器返回失败结果

	    // 客户端定义的错误
	    HTTP_LCC_ERR_PROTOCOLFAIL,   	// 协议解析失败（服务器返回的格式不正确）
	    HTTP_LCC_ERR_CONNECTFAIL,    	// 连接服务器失败/断开连接
	    HTTP_LCC_ERR_CHECKVERFAIL,   	// 检测版本号失败（可能由于版本过低导致）

	    HTTP_LCC_ERR_SVRBREAK,       	// 服务器踢下线
	    HTTP_LCC_ERR_INVITE_TIMEOUT, 	// 邀请超时
	    // 服务器返回错误
	    HTTP_LCC_ERR_ROOM_FULL,   		// 房间人满
	    HTTP_LCC_ERR_NO_CREDIT,   		// 信用点不足
	    /* IM公用错误码 */
	    HTTP_LCC_ERR_NO_LOGIN,   		// 未登录
	    HTTP_LCC_ERR_SYSTEM,     		// 系统错误
	    HTTP_LCC_ERR_TOKEN_EXPIRE, 		// Token 过期了
	    HTTP_LCC_ERR_NOT_FOUND_ROOM, 	// 进入房间失败 找不到房间信息or房间关闭
	    HTTP_LCC_ERR_CREDIT_FAIL, 		// 远程扣费接口调用失败
	    HTTP_LCC_ERR_ROOM_CLOSE,  		// 房间已经关闭
	    HTTP_LCC_ERR_KICKOFF, 			// 被挤掉线 默认通知内容
	    HTTP_LCC_ERR_NO_AUTHORIZED, 	// 不能操作 不是对应的userid
	    HTTP_LCC_ERR_LIVEROOM_NO_EXIST, // 直播间不存在
	    HTTP_LCC_ERR_LIVEROOM_CLOSED, 	// 直播间已关闭
	    HTTP_LCC_ERR_ANCHORID_INCONSISTENT, 	// 主播id与直播场次的主播id不合
	    HTTP_LCC_ERR_CLOSELIVE_DATA_FAIL, 		// 关闭直播场次,数据表操作出错
	    HTTP_LCC_ERR_CLOSELIVE_LACK_CODITION, 	// 主播立即关闭私密直播间, 不满足关闭条件
	    /* 其它错误码*/
	    HTTP_LCC_ERR_USED_OUTLOG, 				// 退出登录 (用户主动退出登录)
	    HTTP_LCC_ERR_NOTCAN_CANCEL_INVITATION, 	// 取消立即私密邀请失败 状态不是带确认 /*important*/
	    HTTP_LCC_ERR_NOT_FIND_ANCHOR, 			// 主播机构信息找不到
	    HTTP_LCC_ERR_NOTCAN_REFUND, 			// 立即私密退点失败，已经定时扣费不能退点
	    HTTP_LCC_ERR_NOT_FIND_PRICE_INFO, 		// 找不到price_setting表信息
	    HTTP_LCC_ERR_ANCHOR_BUSY,			  	// 立即私密邀请失败 主播繁忙--存在即将开始的预约 /*important*/
	    HTTP_LCC_ERR_CHOOSE_TIME_ERR, 			// 预约时间错误 /*important*/
	    HTTP_LCC_ERR_BOOK_EXIST, 				// 用户预约时间段已经存在预约 /*important*/
	    HTTP_LCC_ERR_BIND_PHONE, 				// 手机号码已绑定
	    HTTP_LCC_ERR_RETRY_PHONE, 				// 请稍后再重试
	    HTTP_LCC_ERR_MORE_TWENTY_PHONE, 		// 60分钟内验证超过20次，请24小时后再试
	    HTTP_LCC_ERR_UPDATE_PHONE_FAIL, 		// 更新失败
	    HTTP_LCC_ERR_ANCHOR_OFFLIVE,            // 主播不在线，不能操作
		HTTP_LCC_ERR_VIEWER_AGREEED_BOOKING, 	// 观众已同意预约
		HTTP_LCC_ERR_OUTTIME_REJECT_BOOKING, 	// 预约邀请已超时（当观众拒绝时）
		HTTP_LCC_ERR_OUTTIME_AGREE_BOOKING,   	// 预约邀请已超时（当观众同意时）
};

// 底层状态转换JAVA坐标
int HTTPErrorTypeToInt(HTTP_LCC_ERR_TYPE errType);

/*主播在线状态状态*/
static const int AnchorOnlineStatusArray[] = {
	ONLINE_STATUS_UNKNOWN,
	ONLINE_STATUS_OFFLINE,
	ONLINE_STATUS_LIVE
};

// 底层状态转换JAVA坐标
int AnchorOnlineStatusToInt(OnLineStatus liveRoomStatus);

/*直播间类型*/
static const int LiveRoomTypeArray[] = {
	    HTTPROOMTYPE_NOLIVEROOM,                  // 没有直播间
	    HTTPROOMTYPE_FREEPUBLICLIVEROOM,          // 免费公开直播间
	    HTTPROOMTYPE_COMMONPRIVATELIVEROOM,       // 普通私密直播间
	    HTTPROOMTYPE_CHARGEPUBLICLIVEROOM,        // 付费公开直播间
	    HTTPROOMTYPE_LUXURYPRIVATELIVEROOM        // 豪华私密直播间
};

// 底层状态转换JAVA坐标
int LiveRoomTypeToInt(HttpRoomType liveRoomType);

/*主播VIP类型*/
static const int AnchorLevelTypeArray[] = {
	    ANCHORLEVELTYPE_UNKNOW,             // 未知
	    ANCHORLEVELTYPE_SILVER,             // 白银
	    ANCHORLEVELTYPE_GOLD                // 黄金
};
int AnchorLevelTypeToInt(AnchorLevelType anchorLevelType);

/*立即私密邀请处理状态*/
static const int ImmediateInviteReplyTypeArray[]{
	HTTPREPLYTYPE_UNKNOWN,              // 未知
	HTTPREPLYTYPE_UNCONFIRM,            // 待确定
	HTTPREPLYTYPE_AGREE,                // 已同意
	HTTPREPLYTYPE_REJECT,               // 已拒绝
	HTTPREPLYTYPE_OUTTIME,              // 已超时
	HTTPREPLYTYPE_CANCEL,               // 观众/主播取消
	HTTPREPLYTYPE_ANCHORABSENT,         // 主播缺席
	HTTPREPLYTYPE_FANSABSENT,           // 观众缺席
	HTTPREPLYTYPE_COMFIRMED             // 已完成
};

// 底层状态转换JAVA坐标
int ImmediateInviteReplyTypeToInt(HttpReplyType giftType);

/* 礼物类型  */
static const int GiftTypeArray[]{
	GIFTTYPE_UNKNOWN,
	GIFTTYPE_COMMON,   // 普通礼物
	GIFTTYPE_Heigh  // 高级礼物（动画）
};

// 底层状态转换JAVA坐标
int GiftTypeToInt(GiftType giftType);

/* 预约邀请处理状态 */
static const int BookInviteStatusArray[]{
	BOOKINGREPLYTYPE_UNKNOWN,           // 未知
	BOOKINGREPLYTYPE_PENDING,           // 待确定
	BOOKINGREPLYTYPE_ACCEPT,           // 已接受
	BOOKINGREPLYTYPE_REJECT,           // 已拒绝
	BOOKINGREPLYTYPE_OUTTIME,           // 超时
	BOOKINGREPLYTYPE_CANCEL,           // 取消
	BOOKINGREPLYTYPE_ANCHORABSENT,      // 主播缺席
	BOOKINGREPLYTYPE_FANSABSENT,        // 观众缺席
	BOOKINGREPLYTYPE_COMFIRMED          // 已完成
};

/*预约邀请列表类型*/
static const int BookInviteListTypeArray[] = {
	BOOKINGLISTTYPE_WAITFANSHANDLEING,          // 等待观众处理
	BOOKINGLISTTYPE_WAITANCHORHANDLEING,        // 等待主播处理
	BOOKINGLISTTYPE_COMFIRMED,                  // 已确认
	BOOKINGLISTTYPE_HISTORY                     // 历史
};

//Java层转底层枚举
BookingListType IntToBookInviteListType(int value);

// 底层状态转换JAVA坐标
int BookInviteStatusToInt(BookingReplyType replyType);

/* 才艺邀请状态  */
static const int TalentInviteStatusArray[]{
	HTTPTALENTSTATUS_UNREPLY,               // 未回复
	HTTPTALENTSTATUS_ACCEPT,                // 已接受
	HTTPTALENTSTATUS_REJECT                 // 拒绝
};

// 底层状态转换JAVA坐标
int TalentInviteStatusToInt(HTTPTalentStatus talentStatus);

/* 预约邀请时段可预约状态 */
static const int BookInviteTimeStatusArray[]{
	BOOKTIMESTATUS_BOOKING,             // 可预约
	BOOKTIMESTATUS_INVITEED,            // 本人已邀请
	BOOKTIMESTATUS_COMFIRMED,           // 本人已确认
	BOOKTIMESTATUS_INVITEEDOTHER		// 本人已邀请其它主播
};

// 底层状态转换JAVA坐标
int  BookInviteTimeStatusToInt(BookTimeStatus bookTimeStatus);

/* 预约邀请时段可预约状态 */
static const int VoucherUseRoomTypeArray[]{
	USEROOMTYPE_LIMITLESS,                  // 不限
	USEROOMTYPE_PUBLIC,                     // 公开
	USEROOMTYPE_PRIVATE                     // 私密
};

// 底层状态转换JAVA坐标
int  VoucherUseRoomTypeToInt(UseRoomType useRoomType);

/* 预约邀请时段可预约状态 */
static const int VoucherAnchorTypeArray[]{
	ANCHORTYPE_LIMITLESS,                  // 不限
	ANCHORTYPE_APPOINTANCHOR,              // 指定主播
	ANCHORTYPE_NOSEEANCHOR                 // 没看过直播的主播
};

// 底层状态转换JAVA坐标
int  VoucherAnchorTypeToInt(AnchorType voucherAnchorType);

/*观众用户类型（1：A1类型 2：A2类型） （A1类型：仅可看付费公开及豪华私密直播间， A2类型:可看所有直播间）*/
static const int UserTypeArray[] = {
	    USERTYPEUNKNOW,             // 未知
	    USERTYPEA1,             // A1类型：仅可看付费公开及豪华私密直播间
	    USERTYPEA2                // A2类型:可看所有直播间
};
int UserTypeToInt(UserType userType);

/*视频活动操作类型*/
static const int InteractiveOperateTypeArray[] = {
	CONTROLTYPE_START,                   // 开始
	CONTROLTYPE_CLOSE                    // 关闭
};

//Java层转底层枚举
ControlType IntToInteractiveOperateType(int value);

/*获取界面的类型*/
static const int PromoAnchorTypeArray[] = {
	    PROMOANCHORTYPE_UNKNOW,                             // 未知
	    PROMOANCHORTYPE_LIVEROOM,                           // 直播间
	    PROMOANCHORTYPE_ANCHORPERSONAL                     // 主播个人页
};
//Java层转底层枚举
PromoAnchorType IntToPromoAnchorType(int value);

//c++对象转Java对象
jobjectArray getJavaStringArray(JNIEnv *env, const list<string>& sourceList);
jintArray getJavaIntArray(JNIEnv *env, const list<int>& sourceList);
jintArray getInterestJavaIntArray(JNIEnv *env, const list<InterestType>& sourceList);

jobject getLoginItem(JNIEnv *env, const HttpLoginItem& item);

jobjectArray getHotListArray(JNIEnv *env, const HotItemList& listItem);
jobjectArray getFollowingListArray(JNIEnv *env, const FollowItemList& listItem);
jobjectArray getValidRoomArray(JNIEnv *env, const HttpGetRoomInfoItem::RoomItemList& listItem);
jobjectArray getImmediateInviteArray(JNIEnv *env, const InviteItemList& listItem);
jobjectArray getAudienceArray(JNIEnv *env, const HttpLiveFansList& listItem);
jobjectArray getGiftArray(JNIEnv *env, const GiftItemList& listItem);
jobjectArray getSendableGiftArray(JNIEnv *env, const GiftWithIdItemList& listItem);
jobject getGiftDetailItem(JNIEnv *env, const HttpGiftInfoItem& item);
jobjectArray getEmotionCategoryArray(JNIEnv *env, const EmoticonItemList& listItem);
jobjectArray getTalentArray(JNIEnv *env, const TalentItemList& listItem);
jobject getTalentInviteItem(JNIEnv *env, const HttpGetTalentStatusItem& item);
jobject getAudienceInfoItem(JNIEnv *env, const HttpLiveFansItem& item);

jobject getImmediateInviteItem(JNIEnv *env, const HttpInviteInfoItem& item);
jobjectArray getBookInviteArray(JNIEnv *env, const BookingPrivateInviteItemList& listItem);
jobject getBookInviteConfigItem(JNIEnv *env, const HttpGetCreateBookingInfoItem& item);

jobjectArray getPackgetGiftArray(JNIEnv *env, const BackGiftItemList& listItem);
jobjectArray getPackgetVoucherArray(JNIEnv *env, const VoucherList& listItem);
jobjectArray getPackgetRideArray(JNIEnv *env, const RideList& listItem);

jobject getSynConfigItem(JNIEnv *env, const HttpConfigItem& item);
jobject getAudienceBaseInfoItem(JNIEnv *env, const HttpLiveFansInfoItem& item);
jobjectArray getServerArray(JNIEnv *env, const HttpLoginItem::SvrList& list);
jobject getServerItem(JNIEnv *env, const HttpLoginItem::SvrItem& item);

jobject getUserInfoItem(JNIEnv *env, const HttpUserInfoItem& item);
jobject getAnchorInfoItem(JNIEnv *env, const HttpAnchorInfoItem& item);

#endif