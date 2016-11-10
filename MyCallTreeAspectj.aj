package loglist.util;

public aspect CallTreeAspectj {

    public class Trace {
        private final TTree tTree;

        private Trace(TTree tTree) {
            this.tTree = tTree;
        }
    }

/*
    public static final ThreadLocal<Stack<Long>> costTime = new ThreadLocal<Stack<Long>>() {
        @Override
        protected Stack<Long> initialValue() {
            return new Stack<>();
        }
    };
*/
    public static final ThreadLocal<Long> callStackCount = new ThreadLocal<Long>() {
        @Override
        protected Long initialValue() {
            return 0L;
        }
    };


    public static final ThreadLocal<Trace> traceRef = new ThreadLocal<>();

    public static FixedList logList = null;

    public static void setFixedList(FixedList _logList){
        logList = _logList;
    }

    pointcut callpoint():
            execution(* (
                        (! org.apache.ignite.internal.util..*)
                       && (! org.apache.ignite.internal.binary..*)
                       && (! org.apache.ignite.internal.processors.resource..*)
                       && (! org.apache.ignite.internal.processors.cache.GridCacheProcessor)
                       && (! org.apache.ignite.internal.processors.cache.GridCacheContext)
                       && (! org.apache.ignite.internal.processors.cache.distributed..*)
                       && (! org.apache.ignite.internal.mxbean..*)
                       && (com.tencent.flame.impl4lol..*
                       || com.tangosol..*
                       || org.apache.ignite.events..*
                       || org.apache.ignite.internal..*
                       || org.apache.ignite.compute..*
                       || org.apache.ignite.cache..*
                       )).*(..));
          // execution(* nonono.*.*.*.*(..));

    before(): callpoint() {
        String threadName = Thread.currentThread().getName();
        if (!threadName.startsWith("main") && !threadName.startsWith("RMI TCP Connection")){
            return ;
        }
        String className = thisJoinPoint.getStaticPart().getClass().getSimpleName();
        String methodName = thisJoinPoint.getStaticPart().getSignature().toShortString();
        if (methodName.contains("GridLoggerProxy")
                || methodName.contains("FlameLogger")
                || methodName.contains("GridCacheLogger"))
                //|| methodName.contains(".toString"))
        {
            return ;
        }
        Object[] object = thisJoinPoint.getArgs();
        StringBuilder args = new StringBuilder();
        for (Object _obj:object) {
            if (args.length() > 0) {
                args.append(",");
            }
            if (null != _obj) {
                args.append(_obj.toString());
            }else{
                args.append("null");
            }


        }
       // System.out.println(args.toString());
        //if (costTime.get().size() == 0) {
        if (callStackCount.get() == 0){
            traceRef.set(new Trace(
                            new TTree(true, "Tracing for : " + Thread.currentThread().getName())
                                    .begin(/*className + */":" + methodName + "(" + args.toString()+"))")//"()" )
                    )
            );
        }
        callStackCount.set(callStackCount.get()+1);
        final Trace trace = traceRef.get();
        long tracingLineNumber = thisJoinPoint.getStaticPart().getSourceLocation().getLine();
        String fileName = thisJoinPoint.getStaticPart().getSourceLocation().getFileName();
        //System.out.println("JAWEN"+className + ":" + methodName + "(@" + fileName + ":" + tracingLineNumber + ")");
        if (args != null) {
            trace.tTree.begin(/*className + */":" + methodName + "(#" + args.toString() + ")" + "(@" + fileName + ":" + tracingLineNumber + ")");
        }else{
            trace.tTree.begin(/*className + */":" + methodName + "(#)" + "(@" + fileName + ":" + tracingLineNumber + ")");
        }
    }

    after(): callpoint() {
        String threadName = Thread.currentThread().getName();
        if (!threadName.startsWith("main") && !threadName.startsWith("RMI TCP Connection")){
            return ;
        }
        String methodName = thisJoinPoint.getStaticPart().getSignature().toShortString();
        if (methodName.contains("GridLoggerProxy")
                || methodName.contains("FlameLogger")
                || methodName.contains("GridCacheLogger"))
        {
            return ;
        }
        final Trace trace = traceRef.get();
        if (!trace.tTree.isTop()) {
            trace.tTree.end();
        }
        callStackCount.set(callStackCount.get()-1);
        //if (costTime.get().size() == 0) {
        if (callStackCount.get() == 0){
           /* if (trace.tTree.rendering().startsWith("`---+Tracing for : main")) {
                System.out.println(trace.tTree.rendering());
            }*/
            //只记录主线程的调用堆栈
           /* if (null != logList){
                logList.add(trace.tTree.rendering());
            }*/
            if (null != logList && (trace.tTree.rendering().startsWith("`---+Tracing for : main")
                             ||trace.tTree.rendering().startsWith("`---+Tracing for : RMI TCP Connection")) ){
                logList.add(trace.tTree.rendering());
            }
        }
        //System.out.println("left "+ thisJoinPoint.getStaticPart().getSignature().toShortString());
    }
    /*
    [xxx,yyyms]:

    xxx: 表示运行到该节点时的总时间. yyy: 表示该节点自身使用的时间
     */
}
