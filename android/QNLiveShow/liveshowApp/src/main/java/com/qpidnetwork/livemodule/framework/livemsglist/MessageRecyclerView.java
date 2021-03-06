package com.qpidnetwork.livemodule.framework.livemsglist;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.graphics.Shader;
import android.graphics.Xfermode;
import android.support.annotation.Nullable;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.util.AttributeSet;
import android.view.View;

import com.qpidnetwork.livemodule.framework.livemsglist.interfaces.IListFunction;
import com.qpidnetwork.livemodule.utils.DisplayUtil;
import com.qpidnetwork.qnbridgemodule.util.Log;

import java.util.ArrayList;
import java.util.List;
import java.util.TimerTask;

/**
 * 列表控件
 * Created by Jagger on 2017/6/1.
 */

public class MessageRecyclerView<T extends Object> extends RecyclerView implements IListFunction {
    private int HOLD_TIME = 5 * 1000;           //停留在某消息的时间最大时间

    private Context mContext;
    private RecyclerViewScrollDetector mRecyclerViewScrollDetector;
    private LiveMessageListAdapter mRecyclerViewAdapter;
    private List<T> mLiveMsgItems = new ArrayList<T>();
    private LiveMsgManager mLiveMsgManager;
    private onMsgUnreadListener mOnMsgUnreadListener;
    private int mUnReadSum = 0;                  //未读数
    private java.util.Timer mHoldingTimer;
    private TimerTask mHoldingTask;
    //是否开启消息停留最长时间计时器
    private boolean starHolingTimer = true;
    private String TAG = MessageRecyclerView.class.getSimpleName();

    //半透效果
    private Paint mPaint;
    private LinearGradient linearGradient;
    private int layerId;

    /**
     * 顶部渐进色
     */
    private int gradualColor = 0;

    //设置列表垂直间距
    private int mVerticalSpace = 0;

    /**
     * 数据显示方向
     */
    public enum DisplayDirection{
        TopToBottom,
        BottomToTop
    }

    /**
     * 列表阅读状态
     */
    public enum ReadingStatus{
        Holding,    //被停在某个位置
        Playing     //正在播放最新消息
    }

    //未读数接口
    public interface onMsgUnreadListener{
        void onMsgUnreadSum(int unreadSum);
        void onReadAll();
    }

    public MessageRecyclerView(Context context) {
        super(context);
        init(context);
    }

    public MessageRecyclerView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public MessageRecyclerView(Context context, @Nullable AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        init(context);
    }

    public void init(Context context){
        mContext = context;
        //滑动监听
        mRecyclerViewScrollDetector = new RecyclerViewScrollDetector(){
            @Override
            void onScrollUp() {
            }

            @Override
            void onScrollDown() {
            }

            @Override
            void onLoadMore() {
                loadMore();
                stopHolingTimer();
            }

            @Override
            void onHold() {
//                Log.d(TAG , "onHold-starHolingTimer:"+starHolingTimer);
                if(starHolingTimer){
                    starHolingTimer();
                }
            }
        };
        mRecyclerViewScrollDetector.setScrollThreshold(2);

        addOnScrollListener(mRecyclerViewScrollDetector);

        //默认LinearLayoutManager(item从上到下依次添加，并且第一个添加的item始终在最上面)
        setDisplayDirection(DisplayDirection.TopToBottom);

//        //半透明效果
//        doTopGradualEffect();

        //数据管理
        mLiveMsgManager = new LiveMsgManager<T>();

        //计时器
        mHoldingTimer = new java.util.Timer(true);

    }

    public void setGradualColor(int gradualColor){
        this.gradualColor = gradualColor;
        //半透明效果
        doTopGradualEffect();
    }

    /**顶部半透明效果
     * 参考:http://blog.csdn.net/linyukun6422/article/details/52516022
     */
    private void doTopGradualEffect() {
        Log.d(TAG,"doTopGradualEffect-gradualColor:"+gradualColor);
        mPaint = new Paint();
        mPaint.setColor(Color.RED);
        final Xfermode xfermode = new PorterDuffXfermode(PorterDuff.Mode.DST_IN);
        mPaint.setXfermode(xfermode);
        linearGradient = new LinearGradient(0.0f, 0.0f, 0.0f, 10.0f,
                new int[]{0, 0 == gradualColor ? Color.BLACK : gradualColor}, null, Shader.TileMode.CLAMP);
        addItemDecoration(new ItemDecoration() {
            @Override
            public void onDrawOver(Canvas canvas, RecyclerView parent, State state) {
                super.onDrawOver(canvas, parent, state);

                mPaint.setXfermode(xfermode);
                mPaint.setShader(linearGradient);
                Log.i("hunter", "onDrawOver left: " + parent.getLeft() + " right: " + parent.getRight()
                        + " top: " + parent.getTop() + " bottom: " + parent.getBottom() + "~~~ height: " + parent.getHeight());
                if(parent.getHeight() >= DisplayUtil.dip2px(mContext, 120)) {
                    canvas.drawRect(0.0f, 0.0f, parent.getRight(), DisplayUtil.dip2px(mContext,6f), mPaint);//200
                }
                mPaint.setXfermode(null);
                canvas.restoreToCount(layerId);
            }

            @Override
            public void onDraw(Canvas c, RecyclerView parent, State state) {
                super.onDraw(c, parent, state);
                //mPaint 改为 null 解决第一条黑底及阴影无法修改颜色问题
                layerId = c.saveLayer(0.0f, 0.0f, (float) parent.getWidth(), (float) parent.getHeight(), null, Canvas.ALL_SAVE_FLAG);
            }

            @Override
            public void getItemOffsets(Rect outRect, View view, RecyclerView parent, State state) {
                super.getItemOffsets(outRect, view, parent, state);
                if(parent.getChildPosition(view) != 0){
                    outRect.top = mVerticalSpace;
                }
            }
        });

    }

    public void setVerticalSpace(int space){
        mVerticalSpace = space;
    }

    /**
     *
     * @param adapter
     */
    @Override
    public void setAdapter(LiveMessageListAdapter adapter){
        //Adapter
        mRecyclerViewAdapter = adapter;
        mRecyclerViewAdapter.setDatas(mLiveMsgItems);
        super.setAdapter(mRecyclerViewAdapter);
    }

    @Override
    public void addNewLiveMsg(Object item) {
        ReadingStatus readingStatus = getReadingStatus();
        boolean isAtBottom = !canScrollVertically(1); //值表示是否能向上滚动，false表示已经滚动到底部
        boolean isPlaying = (readingStatus == ReadingStatus.Playing);    //两个结果合并为列表是否播放消息中

        if(mLiveMsgManager.addNewMsg(mLiveMsgItems , item , isPlaying)){
            mRecyclerViewAdapter.notifyDataSetChanged();
            //如果当前状态是在底部
            if(isAtBottom){
                //滑动到底
                scrollToPosition(mLiveMsgItems.size()-1);
            }
        }
        //如果不是最新消息被看到的情况下，去取未读数
        if(!isPlaying){
            mUnReadSum = mLiveMsgManager.getUnreadSum();
            if(mUnReadSum > 0){
                if(this.mOnMsgUnreadListener != null){
                    this.mOnMsgUnreadListener.onMsgUnreadSum(mUnReadSum);
                }
            }
        }
    }

    @Override
    public void setMaxMsgSum(int maxMsgSum) {
        mLiveMsgManager.setMAX_MSG_SUM(maxMsgSum);
    }

    @Override
    public void setHoldingTime(int time) {
        HOLD_TIME = time;
    }

    @Override
    public void setDisplayDirection(DisplayDirection displayDirection) {
        if(displayDirection == MessageRecyclerView.DisplayDirection.TopToBottom){
            //LinearLayoutManager(item从上到下依次添加，并且第一个添加的item始终在最上面)
            LinearLayoutManager linearLayoutManager = new LinearLayoutManager(mContext, LinearLayoutManager.VERTICAL, false);
            setLayoutManager(linearLayoutManager);
        }else if(displayDirection == MessageRecyclerView.DisplayDirection.BottomToTop){
            //LinearLayoutManager(先添加的item会被顶上去，最新添加的item每次都会显示在最下面)
            LinearLayoutManager linearLayoutManager = new LinearLayoutManager(mContext, LinearLayoutManager.VERTICAL, false);
            linearLayoutManager.setStackFromEnd(true);
            setLayoutManager(linearLayoutManager);
        }
    }

    /**
     * 未读消息响应
     * @param listener
     */
    public void setOnMsgUnreadListener(onMsgUnreadListener listener){
        this.mOnMsgUnreadListener = listener;
    }

    /**
     * 列表阅读状态
     * @return
     */
    public ReadingStatus getReadingStatus(){
        ReadingStatus readingStatus;
        boolean isAtBottom = !canScrollVertically(1); //值表示是否能向上滚动，false表示已经滚动到底部
        boolean isVisible = this.getVisibility() != GONE && this.getVisibility() != INVISIBLE;  //列表是否可视
        boolean isPlaying = isAtBottom && isVisible;    //两个结果合并为列表是否播放消息中

        if(isPlaying){
            readingStatus = ReadingStatus.Playing;
        }else {
            readingStatus = ReadingStatus.Holding;
        }

        return readingStatus;
    }

    /**
     * 滑动至底部，阅读最新消息
     */
    public void loadNewestUnreadMsg(){
//        Log.d(TAG,"loadNewestUnreadMsg");
        loadMore();
        scrollToPosition(mLiveMsgItems.size()-1);
    }

    /**
     * 加载更多，会自动滑动底
     */
    public void loadMore(){
//        Log.d(TAG,"loadNewestUnreadMsg");
        if(mLiveMsgManager.getFromCache(mLiveMsgItems)){
//            Log.d(TAG,"loadNewestUnreadMsg-notifyDataSetChanged");
            mRecyclerViewAdapter.notifyDataSetChanged();
        }

        mLiveMsgManager.setReadAll();
//        Log.d(TAG,"loadNewestUnreadMsg-setReadAll");
        if(mOnMsgUnreadListener != null){
            mOnMsgUnreadListener.onReadAll();
        }
    }

    /**
     * 开启 停留计时
     */
    private void starHolingTimer(){
        if(mHoldingTimer != null){
            if(mHoldingTask != null ){
                mHoldingTask.cancel();  //将原任务从队列中移除
            }

            mHoldingTask = new TimerTask() {
                public void run() {
                    //滑动到底
                    post(new Runnable() {
                        @Override
                        public void run() {
                            loadNewestUnreadMsg();
                        }
                    });

                }
            };
        }
        mHoldingTimer.schedule(mHoldingTask , HOLD_TIME);
    }

    /**
     * 停止 停留计时
     */
    private void stopHolingTimer(){
        if(mHoldingTask != null ){
            mHoldingTask.cancel();  //将原任务从队列中移除
        }
    }

    /**
     * 获取最后一条数据（包括列表展示和本地缓存未展示）
     */
    public Object getLastDataItem(){
        Object item = mLiveMsgManager.getLastCacheItem();
        if(item == null){
            if(mLiveMsgItems != null && mLiveMsgItems.size() > 0){
                item = mLiveMsgItems.get(mLiveMsgItems.size() - 1);
            }
        }
        return item;
    }

    /**
     * 2019/4/22 Hardy
     * 停止定时器
     */
    public void onDestroy(){
        if(mHoldingTask != null ){
            mHoldingTask.cancel();
            mHoldingTask = null;
        }
        if (mHoldingTimer != null) {
            mHoldingTimer.cancel();
            mHoldingTimer = null;
        }
    }
}
