#!/bin/bash
# wechattoggle.sh - 微信显示/隐藏切换脚本（极简版，避免dwm崩溃）

# 记录日志
echo "$(date): wechattoggle.sh called" >> /tmp/wechat-toggle.log

# 查找微信进程
WECHAT_PID=$(pgrep -f "/opt/wechat/wechat" | head -n 1)

if [ -z "$WECHAT_PID" ]; then
    # 微信未运行，启动微信
    echo "$(date): 启动微信..." >> /tmp/wechat-toggle.log
    /opt/wechat/wechat > /dev/null 2>&1 &
    echo "$(date): 微信启动命令已执行" >> /tmp/wechat-toggle.log
else
    # 微信已运行，尝试切换窗口
    echo "$(date): 微信已运行，PID: $WECHAT_PID" >> /tmp/wechat-toggle.log
    
    # 尝试多种方式查找微信窗口
    WECHAT_WINDOW=$(wmctrl -lx | grep -i wechat | head -n 1 | awk '{print $1}')
    
    # 如果wmctrl找不到，尝试用xdotool（可能窗口被隐藏了）
    if [ -z "$WECHAT_WINDOW" ]; then
        WECHAT_WINDOW=$(xdotool search --pid $WECHAT_PID 2>/dev/null | head -n 1)
        if [ -n "$WECHAT_WINDOW" ]; then
            WECHAT_WINDOW=$(printf "0x%x" $WECHAT_WINDOW)
            echo "$(date): 通过PID找到隐藏的微信窗口: $WECHAT_WINDOW" >> /tmp/wechat-toggle.log
        fi
    fi
    
    if [ -n "$WECHAT_WINDOW" ]; then
        echo "$(date): 找到微信窗口: $WECHAT_WINDOW" >> /tmp/wechat-toggle.log
        
        # 检查窗口是否当前活动（标准化窗口ID格式进行比较）
        ACTIVE_WINDOW_RAW=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | awk '{print $5}' | tr -d ',')
        ACTIVE_WINDOW=$(printf "0x%08x" $((ACTIVE_WINDOW_RAW)) 2>/dev/null)
        WECHAT_WINDOW_NORMALIZED=$(printf "0x%08x" $((WECHAT_WINDOW)) 2>/dev/null)
        
        echo "$(date): 活动窗口: $ACTIVE_WINDOW, 微信窗口: $WECHAT_WINDOW_NORMALIZED" >> /tmp/wechat-toggle.log
        
        if [ "$WECHAT_WINDOW_NORMALIZED" = "$ACTIVE_WINDOW" ]; then
            # 微信是当前活动窗口，隐藏它（在dwm中使用不同策略）
            echo "$(date): 微信是活动窗口，隐藏" >> /tmp/wechat-toggle.log
            # 在dwm中，我们可以将窗口移到一个空的标签页或使用unmap
            xdotool windowunmap "$WECHAT_WINDOW" 2>/dev/null || \
            wmctrl -i -t 9 "$WECHAT_WINDOW" 2>/dev/null
        else
            # 微信不是活动窗口，显示并激活它
            echo "$(date): 显示并激活微信窗口" >> /tmp/wechat-toggle.log
            # 首先确保窗口是可见的（如果之前被unmap了）
            xdotool windowmap "$WECHAT_WINDOW" 2>/dev/null
            # 然后激活窗口
            wmctrl -i -a "$WECHAT_WINDOW" 2>/dev/null
        fi
        
        echo "$(date): 窗口操作命令已执行" >> /tmp/wechat-toggle.log
    else
        echo "$(date): 未找到微信窗口" >> /tmp/wechat-toggle.log
    fi
fi

echo "$(date): wechattoggle.sh 执行完成" >> /tmp/wechat-toggle.log
