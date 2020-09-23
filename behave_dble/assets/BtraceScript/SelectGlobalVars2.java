package com.actiontech.dble.btrace.script;

import com.sun.btrace.BTraceUtils;
import com.sun.btrace.annotations.BTrace;
import com.sun.btrace.annotations.OnMethod;
import com.sun.btrace.annotations.ProbeClassName;
import com.sun.btrace.annotations.ProbeMethodName;
/*
 the vars2 about hreatbeat
 purpose and usage see SelectGlobalVars1
 */
@BTrace(unsafe = true)
public final class SelectGlobalVars2 {

    private SelectGlobalVars2() {

    }

    @OnMethod(
            clazz = "com.actiontech.dble.sqlengine.SQLJob",
            method = "fieldEofResponse"
    )
    public static void fieldEofResponse(@ProbeClassName String probeClass, @ProbeMethodName String probeMethod) throws Exception {
        BTraceUtils.println("get into fieldEofResponse");
        BTraceUtils.print(" sleep __________________________ ");
        Thread.sleep(10000L);
    }

}