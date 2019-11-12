package com.qpidnetwork.anchor.liveshow.liveroom;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.text.TextUtils;
import android.text.method.LinkMovementMethod;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.facebook.drawee.view.SimpleDraweeView;
import com.qpidnetwork.anchor.R;
import com.qpidnetwork.anchor.framework.livemsglist.LiveMessageListAdapter;
import com.qpidnetwork.anchor.framework.livemsglist.LiveMessageListView;
import com.qpidnetwork.anchor.framework.livemsglist.MessageRecyclerView;
import com.qpidnetwork.anchor.framework.livemsglist.ViewHolder;
import com.qpidnetwork.anchor.im.listener.IMMessageItem;
import com.qpidnetwork.anchor.im.listener.IMRoomInItem;
import com.qpidnetwork.anchor.im.listener.IMSysNoticeMessageContent;
import com.qpidnetwork.anchor.liveshow.model.LiveRoomMsgListItem;
import com.qpidnetwork.anchor.utils.CustomerHtmlTagHandler;
import com.qpidnetwork.anchor.utils.DisplayUtil;
import com.qpidnetwork.anchor.utils.Log;

import java.lang.ref.WeakReference;

/**
 * Description:
 * <p>
 * Created by Harry on 2017/9/4.
 */
public class FullSrceenLiveRoomChatManager {

    private final String TAG = FullSrceenLiveRoomChatManager.class.getSimpleName();

    //控件
    private WeakReference<BaseImplLiveRoomActivity> mActivity;
    private CustomerHtmlTagHandler.Builder mBuilder;
    private LiveMessageListView lvlv_roomMsgList;
    private LiveMessageListAdapter lmlAdapter;
    private TextView tv_unReadTip;
    private LinearLayout ll_unReadTip;

    //变量
    private int riderImgWidth = 0;
    private int riderImgHeight = 0;
    private int giftImgWidth = 0;
    private int giftImgHeight = 0;
    private int anchorFlagImgWidth = 0;
    private int anchorFlagImgHeight = 0;
    private Context mContext;
    private LiveRoomChatMsglistItemManager mLiveRoomChatMsglistItemManager;

    /**
     * 当前直播间类型
     */
    private IMRoomInItem.IMLiveRoomType currLiveRoomType;
    /**
     * 当前主播ID/hangout直播间男士ID
     */
    private String currAnchorId = null;

    private RoomThemeManager roomThemeManager;

    private View.OnClickListener onRoomMsgListClickListener = null;
    public void setOnRoomMsgListClickListener(View.OnClickListener listener){
        if(null != lvlv_roomMsgList){
            lvlv_roomMsgList.setOnClickListener(listener);
        }
        onRoomMsgListClickListener = listener;
    }

    public FullSrceenLiveRoomChatManager(Context context, IMRoomInItem.IMLiveRoomType currLiveRoomType,
                                         String currAnchorId, RoomThemeManager roomThemeManager){
        Log.d(TAG,"LiveRoomChatManager-currLiveRoomType:"+currLiveRoomType+" currAnchorId:"+currAnchorId);
        mContext = context;
        this.currLiveRoomType = currLiveRoomType;
        this.currAnchorId = currAnchorId;
        this.roomThemeManager = roomThemeManager;
    }

    public void init(BaseImplLiveRoomActivity roomActivity, View container){
        mActivity = new WeakReference<BaseImplLiveRoomActivity>(roomActivity);
        //初始化Html图片解析器
        riderImgWidth = (int)roomActivity.getResources().getDimension(R.dimen.liveroom_messagelist_rider_width);
        riderImgHeight = (int)roomActivity.getResources().getDimension(R.dimen.liveroom_messagelist_rider_height);
        giftImgWidth = (int)roomActivity.getResources().getDimension(R.dimen.liveroom_messagelist_gift_width);
        giftImgHeight = (int)roomActivity.getResources().getDimension(R.dimen.liveroom_messagelist_gift_height);
        anchorFlagImgWidth = (int)roomActivity.getResources().getDimension(R.dimen.liveroom_messagelist_anchor_flag_width);
        anchorFlagImgHeight = (int)roomActivity.getResources().getDimension(R.dimen.liveroom_messagelist_anchor_flag_height);
        mBuilder = new CustomerHtmlTagHandler.Builder();
        mBuilder.setContext(mContext)
                .setAnchorFlagImgHeight(this.anchorFlagImgHeight)
                .setAnchorFlagImgWidth(this.anchorFlagImgWidth)
                .setGiftImgHeight(this.giftImgHeight)
                .setGiftImgWidth(this.giftImgWidth)
                .setRiderImgWidth(this.riderImgWidth)
                .setRiderImgHeight(this.riderImgHeight);
        lvlv_roomMsgList = (LiveMessageListView) container.findViewById(R.id.lvlv_roomMsgList);
        ll_unReadTip = (LinearLayout) container.findViewById(R.id.ll_unReadTip);
        ll_unReadTip.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                lvlv_roomMsgList.loadNewestUnreadMsg();
            }
        });
        tv_unReadTip = (TextView) container.findViewById(R.id.tv_unReadTip);
        tv_unReadTip.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                lvlv_roomMsgList.loadNewestUnreadMsg();
            }
        });
        lvlv_roomMsgList.setOnMsgUnreadListener(new MessageRecyclerView.onMsgUnreadListener() {
            @Override
            public void onMsgUnreadSum(int unreadSum) {
                updateUnreadLiveMsgTipVew(unreadSum);
            }

            @Override
            public void onReadAll() {
                Log.d(TAG,"onReadAll");
                updateUnreadLiveMsgTipVew(0);
            }
        });
        lmlAdapter = new LiveMessageListAdapter<LiveRoomMsgListItem>(roomActivity,R.layout.item_live_room_msglist) {
            @Override
            public void convert(ViewHolder holder, LiveRoomMsgListItem liveMsgItem) {
                doDrawItem(holder, liveMsgItem);
            }
        };

        lvlv_roomMsgList.setAdapter(lmlAdapter);
        lvlv_roomMsgList.setMaxMsgSum(mContext.getResources().getInteger(R.integer.liveMsgListMaxNum));
        lvlv_roomMsgList.setHoldingTime(mContext.getResources().getInteger(R.integer.liveMsgListItemHoldTime));
        lvlv_roomMsgList.setVerticalSpace(Float.valueOf(mContext.getResources().getDimension(
                currLiveRoomType == IMRoomInItem.IMLiveRoomType.HangoutRoom ?
                        R.dimen.listmsgview_item_vert_space_hangout : R.dimen.listmsgview_item_vert_space)).intValue());
        lvlv_roomMsgList.setGradualColor(roomThemeManager.getRoomMsgListTopGradualColor(currLiveRoomType));
        lvlv_roomMsgList.setDisplayDirection(MessageRecyclerView.DisplayDirection.BottomToTop); //数据从底向上排

        initMsgListCache();
    }

    /**
     * 一定要调用
     */
    public void destroy(){
        if(mLiveRoomChatMsglistItemManager != null){
            mLiveRoomChatMsglistItemManager.destroy();
        }
    }

    /**
     * 更新未读消息提示界面
     * @param unReadNum
     */
    private void updateUnreadLiveMsgTipVew(int unReadNum){
        Log.d(TAG,"updateUnreadLiveMsgTipVew-unReadNum:"+unReadNum);
        ll_unReadTip.setVisibility(0 == unReadNum ? View.INVISIBLE : View.VISIBLE);
        tv_unReadTip.setText(mContext.getString(R.string.tip_unReadLiveMsg,unReadNum));
    }

    /**
     * 初始化列表ITEM缓冲处理Spanned工具
     */
    private void initMsgListCache(){
        mLiveRoomChatMsglistItemManager = new LiveRoomChatMsglistItemManager(mContext, currLiveRoomType , mBuilder , roomThemeManager, currAnchorId);
        mLiveRoomChatMsglistItemManager.setListItemSpannedListener(new LiveRoomChatMsglistItemManager.onMsgItemSpannedListener() {
            @Override
            public void onSpanned(LiveRoomMsgListItem liveRoomMsgListItem) {
                //接收处理从缓冲区回来的数据
                lvlv_roomMsgList.addNewLiveMsg(liveRoomMsgListItem);
            }
        });
    }

    /**
     * 给列表控件赋值
     * @param holder
     * @param msgListItem
     */
    private void doDrawItem(ViewHolder holder,
                            LiveRoomMsgListItem msgListItem){
        IMMessageItem liveMsgItem = msgListItem.imMessageItem;
        View ll_msgItemContainer = holder.getView(R.id.ll_msgItemContainer);
        //控件
        ll_msgItemContainer.setOnClickListener(onRoomMsgListClickListener);
        //文字
        TextView tvMsgDescription = holder.getView(R.id.tvMsgDescription);
        TextView tvName = holder.getView(R.id.tvName);
        //避免itemview循环利用时背景色混乱
        tvMsgDescription.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        //设置padding
        tvMsgDescription.setMinHeight(0);
        tvMsgDescription.setPadding(0,0,0,0);
        if(null == liveMsgItem.sysNoticeContent || TextUtils.isEmpty(liveMsgItem.sysNoticeContent.link)){
            tvMsgDescription.setOnClickListener(onRoomMsgListClickListener);
        }
        //推荐信息
        LinearLayout llRecommended = holder.getView(R.id.llRecommended);
        llRecommended.setVisibility(View.GONE); //默认隐藏
        SimpleDraweeView imgMsgAnchorPhoto = holder.getView(R.id.imgMsgAnchorPhoto);
        TextView tvMsgAnchorName = holder.getView(R.id.tvMsgAnchorName);
        TextView tvAnchorYrs = holder.getView(R.id.tvAnchorYrs);
//        TextView tvAnchorLocal = holder.getView(R.id.tvAnchorLocal);

        switch (liveMsgItem.msgType){
            case Normal:
            case Barrage:{
                //名字和背景色
                if(currLiveRoomType == IMRoomInItem.IMLiveRoomType.HangoutRoom){
                    //hangOut
                }else{
                    //公开 & 私密
                    boolean isAnchorMsg = msgListItem.imMessageItem.userId.equals(currAnchorId);
                    tvName.setVisibility(View.VISIBLE);
                    tvName.setText(msgListItem.imMessageItem.nickName);
                    tvName.setBackground(
                            roomThemeManager.getFullScreenRoomNickNameBgDrawable(mContext, currLiveRoomType,isAnchorMsg));

                    //设置消息背景
                    ll_msgItemContainer.setBackgroundDrawable(
                            roomThemeManager.getFullScreenRoomNorMsgItemBgDrawable(
                                    mContext, currLiveRoomType));
                }

            }break;
            case Gift:{
                if(currLiveRoomType == IMRoomInItem.IMLiveRoomType.HangoutRoom){
                    int margin = DisplayUtil.dip2px(mActivity.get(),9f);
                    int space = DisplayUtil.dip2px(mActivity.get(),3f);
                    tvMsgDescription.setPadding(margin,space,margin,space);
                    tvMsgDescription.setMinHeight(DisplayUtil.dip2px(mActivity.get(),26f));

                    tvMsgDescription.setBackgroundDrawable(
                            roomThemeManager.getRoomMsgListGiftItemBgDrawable(
                                    mContext, currLiveRoomType,liveMsgItem.giftMsgContent.isSecretly));
                }else {
                    //名字和背景色
                    boolean isAnchorGift = msgListItem.imMessageItem.userId.equals(currAnchorId);
                    tvName.setVisibility(View.VISIBLE);
                    tvName.setText(msgListItem.imMessageItem.nickName);
                    tvName.setBackground(
                            roomThemeManager.getFullScreenRoomNickNameBgDrawable(mContext, currLiveRoomType,isAnchorGift));

                    //设置消息背景
                    ll_msgItemContainer.setBackgroundDrawable(
                            roomThemeManager.getFullScreenRoomNorMsgItemBgDrawable(
                                    mContext, currLiveRoomType));
                }


            }break;
            case FollowHost:{
                //FollowHost系统以公告方式推送给客户端
            }break;
            case RoomIn:{
                //入场消息类型
                tvName.setVisibility(View.GONE);
                //设置消息背景
                ll_msgItemContainer.setBackgroundDrawable(
                        roomThemeManager.getFullScreenRoomNorMsgItemBgDrawable(
                                mContext, currLiveRoomType));
            }break;
            case SysNotice: {
                final IMSysNoticeMessageContent msgContent = msgListItem.imMessageItem.sysNoticeContent;
                if (msgContent != null) {
                    tvName.setVisibility(View.GONE);

                    if (!TextUtils.isEmpty(msgContent.link)) {
                        //连接
                        tvMsgDescription.setText(msgListItem.spanned);
                        //设置消息背景
                        ll_msgItemContainer.setBackgroundDrawable(
                                roomThemeManager.getFullScreenRoomMineSysMsgItemBgDrawable(
                                        mContext, currLiveRoomType));
                    }else{
                        //其它类型的系统提示
                        if(msgContent.sysNoticeType == IMSysNoticeMessageContent.SysNoticeType.Normal){
                            tvMsgDescription.setText(msgListItem.spanned);
                            //设置消息背景
                            ll_msgItemContainer.setBackgroundDrawable(
                                    roomThemeManager.getFullScreenRoomMineSysMsgItemBgDrawable(
                                            mContext, currLiveRoomType));
                        }else if(msgContent.sysNoticeType == IMSysNoticeMessageContent.SysNoticeType.CarIn){
                            //座驾入场从公告类型修改为RoomIn类型

                        }else if(msgContent.sysNoticeType == IMSysNoticeMessageContent.SysNoticeType.Warning){
                            tvMsgDescription.setText(msgListItem.spanned);
                            //设置消息背景
                            ll_msgItemContainer.setBackgroundDrawable(
                                    roomThemeManager.getFullScreenRoomWarningMsgItemBgDrawable(
                                            mContext, currLiveRoomType));
                        }else{
                            //设置消息背景
                            ll_msgItemContainer.setBackgroundDrawable(
                                    roomThemeManager.getFullScreenRoomMineSysMsgItemBgDrawable(
                                            mContext, currLiveRoomType));
                        }
                    }
                }
            }break;
            case HangOut:{
                llRecommended.setVisibility(View.VISIBLE);
                imgMsgAnchorPhoto.setImageURI(liveMsgItem.hangoutRecommendItem.friendPhotoUrl);
                tvMsgAnchorName.setText(liveMsgItem.hangoutRecommendItem.friendNickName);
//                tvAnchorYrs.setText(liveMsgItem.hangoutRecommendItem.friendAge + " yrs / ");
//                tvAnchorLocal.setText(liveMsgItem.hangoutRecommendItem.friendCountry);
                tvAnchorYrs.setText(mContext.getString(R.string.hangout_dialog_des,liveMsgItem.hangoutRecommendItem.friendAge, liveMsgItem.hangoutRecommendItem.friendCountry));
            }break;

            default:
                break;
        }
        tvMsgDescription.setMovementMethod(liveMsgItem.msgType == IMMessageItem.MessageType.SysNotice
                ? LinkMovementMethod.getInstance() : null);
        if(null != msgListItem.spanned){
            tvMsgDescription.setText(msgListItem.spanned);
        }
    }

//    @Override
//    public void onCompleted(boolean isSuccess, String localFilePath, String fileUrl) {
//        Log.i(TAG, "LiveRoomChatManager-onCompleted isSuccess：" + isSuccess
//                +" localFilePath:"+localFilePath+" fileUrl:"+fileUrl);
//        if(isSuccess){
//            if(null != mActivity && null != mActivity.get()){
//                mActivity.get().runOnUiThread(new Runnable() {
//                    @Override
//                    public void run() {
//                        //图片下载更新列表
//                        if(lmlAdapter != null) {
//                            lmlAdapter.notifyDataSetChanged();
//                        }
//                    }
//                });
//            }
//        }
//    }

    public void addMessageToList(final IMMessageItem msgItem){
        if(IMMessageItem.MessageType.RoomIn == msgItem.msgType){
            Log.d(TAG,"addMessageToList-msgItem.txtMsg:"+msgItem.textMsgContent);
        }
//        boolean isUpdate = false;

        //del by Jagger 2018-5-23
        //这段会导致 lvlv_roomMsgList 里数据错乱，出现BUG#11038, 参考观众端不需要这段代码
        //最后一条消息是RoomIn时，更新
//        if(msgItem.msgType == IMMessageItem.MessageType.RoomIn){
//            Object dataItem = lvlv_roomMsgList.getLastData();
//            if(dataItem != null && dataItem instanceof IMMessageItem){
//                IMMessageItem lastMsgitem = (IMMessageItem)dataItem;
//                if(lastMsgitem.msgType == IMMessageItem.MessageType.RoomIn){
//                    isUpdate = false;//true则为更新最后一条RoomIn消息提示，false则新插入
//                    lastMsgitem.copy(msgItem);
//                }
//            }
//        }

        //del by Jagger 2018-6-20
//        if(lvlv_roomMsgList != null && !isUpdate){
//            Log.d(TAG,"addMessageToList-插入RoomIn消息");
//            lvlv_roomMsgList.addNewLiveMsg(msgItem);
//        }else{
//            Log.d(TAG,"addMessageToList-更新RoomIn消息");
//            lmlAdapter.notifyDataSetChanged();å
//        }

        //edit by Jagger 2018-6-20 交由管理器异步转化HTML文本
        if(lvlv_roomMsgList != null){
            Log.d(TAG,"addMessageToList-插入RoomIn消息");
            //放放缓冲区
            if(mLiveRoomChatMsglistItemManager != null){
                mLiveRoomChatMsglistItemManager.addMsgListItem(msgItem);
            }
        }else{
            Log.d(TAG,"addMessageToList-更新RoomIn消息");
            lmlAdapter.notifyDataSetChanged();
        }
        //end
    }

}
