package com.actiontech.dble.btrace.script;
 
import com.sun.btrace.BTraceUtils;
import com.sun.btrace.annotations.BTrace;
import com.sun.btrace.annotations.OnMethod;
 
@BTrace(unsafe = true)
public final class BtraceHeartbeat {
 
    private BtraceHeartbeat() {
 
    }
   @OnMethod(
            clazz = "com.actiontech.dble.sqlengine.HeartbeatSQLJob",
            method = "fieldEofResponse"
    )
    public static void fieldEofResponse() throws Exception {
        BTraceUtils.println("before fieldEofResponse_________________---1 " );
        BTraceUtils.println("before fieldEofResponse_____________--2 " );
        Thread.sleep(3600000L);
        BTraceUtils.println("before fieldEofResponse_____________--3 " );
    }
}
 