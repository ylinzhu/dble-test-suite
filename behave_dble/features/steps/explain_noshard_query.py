# -*- coding: utf-8 -*-
# @Time    : 2019/8/28 AM11:16
# @Author  : zhaohongjie@actionsky.com
def do_explain_for_sql(context, id, sql, to_close):
    targets = ["special_nosharding/select/join_no_sharding.sql", "special_nosharding/select/reference_no_sharding.sql","special_nosharding/select/subquery_no_sharding.sql"]
    if context.sql_file in targets:
        explain_sql = "explain {0}".format(sql)
        result, err = context.conn_dble.query(explain_sql)
        if result is not None and len(result) != 1:
            with open("logs/explain_err.log", 'a') as fpT:
                fpT.writelines("===file:{2}, id:{0}, sql:[{1}]===\n".format(id, sql, context.sql_file))
                result = "{0}\n".format(str(result))
                fpT.writelines(result)
        else:
            with open("logs/explain_pass.log", 'a') as fpT:
                fpT.writelines("===file:{2}, id:{0}, sql:[{1}]===\n".format(id, sql, context.sql_file))
                result = "{0}\n".format(str(result))
                fpT.writelines(str(result))
    else:
        context.logger.debug("context.sql_file: {0}".format(context.sql_file))