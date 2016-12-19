namespace Ypf\Lib;

use \PDO;
use \PDOException;
class DatabaseV5 {

    static    option    = [];
    protected db_config = [];
    protected options   = [];
    protected params    = [];
    protected lastsql   = "";
    protected dsn       = null;
    protected pdo       = null;
    protected exp     = [
        "eq"            : "=",
        "neq"           : "<>",
        "gt"            : ">",
        "egt"           : ">=",
        "lt"            : "<",
        "elt"           : "<=",
        "notlike"       : "NOT LIKE",
        "like"          : "LIKE",
        "in"            : "IN",
        "notin"         : "NOT IN",
        "not in"        : "NOT IN",
        "between"       : "BETWEEN",
        "not between"   : "NOT BETWEEN",
        "notbetween"    : "NOT BETWEEN"
    ];

    protected methods = [
        "from", "data", "field", "table", "order",
        "alias", "having", "group", "lock", "distinct", "auto",
        "fetch"
    ];

    protected adapter_pdostatement = null;


    public function __construct(options = []) {
        var default_options = [
            "dbtype"       : "mysql",
            "host"         : "127.0.0.1",
            "port"         : 3306,
            "dbname"       : "test",
            "username"     : "root",
            "password"     : "",
            "charset"      : "utf8",
            "timeout"      : 3,
            "long_connect" : false
        ];
        let self::option    = array_merge(default_options, options);
        let $this->db_config = self::option;
        let $this->dsn       = $this->createDsn(self::option);
    }
    
    private function createDsn(options = []) {
        var dsn_string;
        let dsn_string = options["dbtype"] . ":host=" . options["host"] . ";dbname=" . options["dbname"] . ";port=" . options["port"];
        return dsn_string;
    }

    public function setAdapter(var adapter) {
        let this->adapter_pdostatement = adapter;
    }
    
   public function query(query = "", data = []) {
       let $this->lastsql = $this->setLastSql(query, data);
       if ("cli" == PHP_SAPI) {
           var e = null;
           try {
               $this->connection()->getAttribute(\PDO::ATTR_SERVER_INFO);
           } catch \PDOException, e {
               if (e->getCode() != "HY000"
               || !stristr(e->getMessage(), "server has gone away")) {
                   throw e;
               }
               $this->reconnect();
           }
       }
       var stmt = $this->connection()->prepare(query);
       stmt->execute(data);
       let $this->params = [];
       let $this->options = $this->params;
       return stmt;
   }
    
    public function reconnect() {
        let $this->pdo = null;
        return $this->connect();
    }

    protected function connection() {
        //return $this->pdo instanceof \PDO ? $this->pdo : $this->connect();
        return empty($this->pdo) ? $this->connect() : $this->pdo ;
    }

    public function connect() {
        var e = null;
        try {
            var option                   = [];
            if(isset self::option["charset"]){
                let option[\PDO::MYSQL_ATTR_INIT_COMMAND] = "SET NAMES " . self::option["charset"];
            }
            let option[\PDO::ATTR_TIMEOUT]    = self::option["timeout"];
            let $this->pdo                    = new \PDO(
                $this->dsn,
                self::option["username"],
                self::option["password"],
                option
            );
            $this->pdo->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
        } catch \Exception ,e {
            throw new \Exception(e);
        }
        return $this->pdo;
    }
    
    public function insert(data = []) {
        let $this->options["type"] = "INSERT";
        return $this->save(data);
    }
    
    public function save(data = []) {

        let $this->options["data"] = "array" == typeof data ? data : [];
        if (!isset $this->options["type"]) {
            let $this->options["type"] = isset $this->options["where"] ? "UPDATE" : "INSERT";
        }
        var data_keys = null, data_fields = null;
        var query_string = null;
        var placeholder = null;
        var res_save = false;
        switch $this->options["type"] {
            case "INSERT":
                let data_keys        = array_keys($this->options["data"]);
                let data_fields      = "`" . implode("`, `", data_keys) . "`";

                let placeholder = substr(str_repeat("?,", count(data_keys)), 0, -1);
                let query_string       = "INSERT INTO `" . $this->options["table"] . "`(" . data_fields . ") VALUES(" . placeholder . ")";
                let res_save = $this->query(query_string, array_values(data)) ? ($this->pdo->lastInsertId() ? $this->pdo->lastInsertId() : true) : false;
                break;
            case "UPDATE":
                var update_field = [];
                let $this->params = array_merge(array_values($this->options["data"]), $this->params);
                var for_k = null;
                for for_k, _ in $this->options["data"] {
                    let update_field[] = "`".for_k."`= ?";
                }
                let query_string = "UPDATE `" . $this->options["table"] . "` SET " . implode(",", update_field) . " WHERE " . implode(" AND ", $this->options["where"]);
                $this->query(query_string, $this->params);
                let res_save = true;
                break;
            case "DELETE":
                let query_string = "DELETE FROM `" . $this->options["table"] . "` WHERE " . implode(" AND ", $this->options["where"]);
                $this->query(query_string, $this->params);
                let res_save = true;
                break;
            default:
                break;
        }
        return res_save;
    }
    
    
    public function select(sql = null, data = []) {
        let sql  = !empty sql ? sql : $this->getQuery();
        let data = empty(data) ? $this->params : data;
        var stmt = $this->query(sql, data);
        var result = stmt->fetchAll(\PDO::FETCH_ASSOC);
        return result;
    }

    public function fetcher(sql = null) {
        let sql = !empty sql ? sql : $this->getQuery();

        var stmt   = $this->query(sql, $this->params);
        $this->setAdapter(stmt);
        var result = null;
        if(!empty $this->adapter_pdostatement){
            var adapter_pdostatement_method = "fetch";
            let result = $this->adapter_pdostatement->{adapter_pdostatement_method}(\PDO::FETCH_ASSOC);
        }
        return empty result ? [] : result;
    }


    public function update(data = []) {
        let $this->options["type"] = "UPDATE";
        return $this->save($data);
    }

    public function delete() {
        let $this->options["type"] = "DELETE";
        return $this->save();
    }

    public function fetchOne(sql = null) {
        let $this->options["limit"] = 1;
        let sql                    = !empty sql ? sql : $this->getQuery();

        var stmt   = $this->query(sql, $this->params);
        $this->setAdapter(stmt);
        var result = null;
        if(!empty $this->adapter_pdostatement){
            var adapter_pdostatement_method = "fetch";
            let result = $this->adapter_pdostatement->{adapter_pdostatement_method}(\PDO::FETCH_NUM);
        }
        return isset result[0] ? result[0] : null;
    }
    
    private function getQuery() {
        var sql = "SELECT ";
        //parse field
        if (isset($this->options["field"])) {
            let sql .= " " . $this->options["field"] . " ";
        } else {
            let sql .= " * ";
        }
        //parse table
        if (isset($this->options["table"])) {
            let sql .= " FROM " . $this->options["table"] . " ";
        }
        //parse join
        if (isset($this->options["join"])) {
            let sql .= $this->options["join"] . " ";
        }
        //parse where
        if (isset($this->options["where"])) {
            let sql .= " WHERE " . implode(" AND ", $this->options["where"]) . " ";
        }
        //parse group
        if (isset($this->options["group"]) && !empty($this->options["group"])) {
            let sql .= " GROUP BY " . $this->options["group"] . " ";
        }
        //parse having
        if (isset($this->options["having"])) {
            let sql .= " HAVING " . $this->options["having"] . " ";
        }
        //parse order
        if (isset($this->options["order"])) {
            let sql .= " ORDER BY " . $this->options["order"] . " ";
        }
        //parse limit
        if (isset($this->options["limit"])) {
            let sql .= " LIMIT " . $this->options["limit"];
        }
        return sql;
    }
    
    private function setLastSql(sql_string = "", data = []) {
        var indexed = false;
        if(data == array_values(data)){
            let indexed = true;
        }
        var for_k = null, for_v = null;
        if("array" == typeof data){
            for for_k , for_v in data {

                if (indexed) {
                    let sql_string = preg_replace("/\?/", for_v, sql_string, 1);
                }else{
                    let sql_string = str_replace(":" . for_k, for_v, sql_string);
                }
            }
        }

        return sql_string;
    }

    public function getLastSql() {
        return $this->lastsql;
    }
    
    public function __call(method_call = "", args = []) {
        if("fetch" == method_call){
            return $this->fetcher(args);
        }elseif (in_array(strtolower(method_call), $this->methods, true)) {
            let $this->options[strtolower(method_call)] = args[0];
            return $this;
        } elseif (in_array(strtolower(method_call), ["count", "sum", "min", "max", "avg"], true)) {
            var field_name                  = (isset(args[0]) && !empty(args[0])) ? args[0] : "*";
            var as_value                     = "_" . strtolower(method_call);
            let $this->options["field"] = strtoupper(method_call) . "(" . field_name . ") AS " . as_value;
            return $this->fetchOne();
        } else {
            return null;
        }
    }
    
    public function addParams(params = null) {
        if (empty params) {
            return;
        }

        if ("array" != typeof params) {
            let params = [params];
        }

        let $this->params = array_merge($this->params, params);
    }
    
    public function where() {
        var args      = func_get_args();
        var statement = null;
        var params = null;
        var query_w   = [];

        if (1 == func_num_args() && isset args[0] && is_array(args[0])) {
            var for_k = null;
            for for_k, _ in args[0] {
                let query_w[] = "`".for_k."` = ?";
            }
            let statement = implode(" AND ", query_w);
            let params    = array_values(args[0]);
        } else {
            let statement = array_shift(args);
            let params = isset(args[0]) && is_array(args[0]) ? args[0] : args;
        }
        if (!empty(statement)) {
            let $this->options["where"][] = statement;
            $this->addParams($params);
        }
        return $this;
    }
    
    public function limit(offset = 0, length = null) {
        let $this->options["limit"] = is_null(length) ? offset : offset . "," . length;
        return $this;
    }


    /**
     * where分析
     * @access protected
     * @param mixed $where
     * @return string
     */
    public function parseWhere(where = null) {
        var whereStr = "";
        if ("string" == typeof where) {
            // 直接使用字符串条件
            let whereStr = where;
        } else { // 使用数组表达式
            var operate = null;
            let operate = isset(where["_logic"]) ? strtoupper(where["_logic"]) : "";
            if (in_array(operate, ["AND", "OR", "XOR"])) {
                // 定义逻辑运算规则 例如 OR XOR AND NOT
                let operate = " " . operate . " ";
                unset(where["_logic"]);
            } else {
                // 默认进行 AND 运算
                let operate = " AND ";
            }
            var for_k = null, for_v = null;
            for for_k , for_v in where {
                if (is_numeric(for_k)) {
                    let for_k = "_complex";
                }
                if (0 === strpos(for_k, "_")) {
                    // 解析特殊条件表达式
                    let whereStr .= $this->parseThinkWhere(for_k, for_v);
                } else {
                    // 查询字段的安全过滤
                    // if(!preg_match("/^[A-Z_\|\&\-.a-z0-9\(\)\,]+$/",trim(for_k))){
                    //     E(L("_EXPRESS_ERROR_").":".for_k);
                    // }
                    // 多条件支持
                    var multi = false;
                    if("array" == typeof for_v && isset for_v["_multi"]){
                        let multi = true;
                    }
                    let for_k   = trim(for_k);
                    var for_k_arr = [], str_arr = [];
                    if (strpos(for_k, "|")) {
                        // 支持 name|title|nickname 方式定义查询字段
                        let for_k_arr = explode("|", for_k);
                        let str_arr   = [];
                        var for_son_k = null, for_son_v = null;
                        for for_son_k, for_son_v in for_k_arr {
                            var new_val = null;
                            let new_val = multi ? for_v[for_son_k] : for_v;
                            let str_arr[] = $this->parseWhereItem($this->parseKey(for_son_v), new_val);
                        }
                        let whereStr .= "( " . implode(" OR ", str_arr) . " )";
                    } elseif (strpos(for_k, "&")) {
                        let for_k_arr = explode("&", for_k);
                        let str_arr   = [];
                        var for_son_k = null, for_son_v = null;
                        for for_son_k, for_son_v in for_k_arr {
                            var new_val = null;
                            let new_val = multi ? for_v[for_son_k] : for_v;
                            let str_arr[] = "(" . $this->parseWhereItem($this->parseKey(for_son_v), new_val) . ")";
                        }
                        let whereStr .= "( " . implode(" AND ", str_arr) . " )";
                    } else {
                        let whereStr .= $this->parseWhereItem($this->parseKey(for_k), for_v);
                    }
                }
                let whereStr .= operate;
            }
            let whereStr = substr(whereStr, 0, -strlen(operate));
        }
        return empty(whereStr) ? "" : " " . whereStr;
    }
    
    // where子单元分析
    protected function parseWhereItem(key = null, val = null) {
        var whereStr = "";
        var matches = null;
        if ("array" == typeof val) {
            if ("string" == typeof val[0]) {
                var exp_value = strtolower(val[0]);
                if (preg_match("/^(eq|neq|gt|egt|lt|elt)$/", exp_value, matches)) { // 比较运算
                    let whereStr .= key . " " . $this->exp[exp_value] . " " . $this->parseValue(val[1]);
                } elseif (preg_match("/^(notlike|like)$/", exp_value, matches)) {// 模糊查找
                    if (is_array(val[1])) {
                        var likeLogic = isset(val[2]) ? strtoupper(val[2]) : "OR";
                        if (in_array(likeLogic, ["AND", "OR", "XOR"])) {
                            var like = [], for_v = null;
                            for for_v in val[1] {
                                let like[] = key . " " . $this->exp[exp_value] . " " . $this->parseValue(for_v);
                            }
                            let whereStr .= "(" . implode(" " . likeLogic . " ", like) . ")";
                        }
                    } else {
                        let whereStr .= key . " " . $this->exp[exp_value] . " " . $this->parseValue(val[1]);
                    }
                } elseif ("bind" == exp_value) { // 使用表达式
                    let whereStr .= key . " = :" . val[1];
                } elseif ("exp" == exp_value) { // 使用表达式
                    let whereStr .= key . " " . val[1];
                } elseif (preg_match("/^(notin|not in|in)$/", exp_value, matches)) { // IN 运算
                    if (isset(val[2]) && "exp" == val[2]) {
                        let whereStr .= key . " " . $this->exp[exp_value] . " " . val[1];
                    } else {
                        if (is_string(val[1]) || is_numeric(val[1])) {
                            let val[1] = explode(",", val[1]);
                        }
                        var zone = implode(",", $this->parseValue(val[1]));
                        let whereStr .= key . " " . $this->exp[exp_value] . " (" . zone . ")";
                    }
                } elseif (preg_match("/^(notbetween|not between|between)$/", exp_value, matches)) { // BETWEEN运算
                    var data = is_string(val[1]) ? explode(",", val[1]) : val[1];
                    let whereStr .= key . " " . $this->exp[exp_value] . " " . $this->parseValue(data[0]) . " AND " . $this->parseValue(data[1]);
                } else {
                    var_dump("parseWhereItem error!");
                    return;
                }
            } else {
                var count_val = count(val);
                var rule = "";
                if(isset(val[count_val - 1])){
                    let rule = is_array(val[count_val - 1]) ? strtoupper(val[count_val - 1][0]) : strtoupper(val[count_val - 1]);
                }
                if (in_array(rule, ["AND", "OR", "XOR"])) {
                    let count_val = count_val - 1;
                } else {
                    let rule = "AND";
                }
                var loop_i = 0;
                while loop_i < count_val {
                    let loop_i++;
                    var data = null;
                    let data = isset val[loop_i][1] ? val[loop_i][1] : val[loop_i];
                    if ("exp" == strtolower(val[loop_i][0])) {
                        let whereStr .= key . " " . data . " " . rule . " ";
                    } else {
                        let whereStr .= $this->parseWhereItem(key, val[loop_i]) . " " . rule . " ";
                    }
                }
                let whereStr = "( " . substr(whereStr, 0, -4) . " )";
            }
        } else {
            //对字符串类型字段采用模糊匹配
            var likeFields = "title|remark";
            if (likeFields && preg_match("/^(" . likeFields . ")$/i", key, matches)) {
                let whereStr .= key . " LIKE " . $this->parseValue("%" . val . "%");
            } else {
                let whereStr .= key . " = " . $this->parseValue(val);
            }
        }
        return whereStr;
    }
    

    /**
     * 特殊条件分析
     * @access protected
     * @param string key
     * @param mixed  val
     * @return string
     */
    protected function parseThinkWhere(key = null, val = null) {
        var whereStr = "";
        switch (key) {
            case "_string":
                // 字符串模式查询条件
                let whereStr = val;
                break;
            case "_complex":
                // 复合查询条件
                let whereStr = substr($this->parseWhere(val), 6);
                break;
            case "_query":
                // 字符串模式查询条件
                var where = [];
                var op = "";
                parse_str(val, where);
                if (isset(where["_logic"])) {
                    let op = " " . strtoupper(where["_logic"]) . " ";
                    unset(where["_logic"]);
                } else {
                    let op = " AND ";
                }
                var op_arr = [];
                var for_k = null, for_v = null;
                for for_k, for_v in where {
                    let op_arr[] = $this->parseKey(for_k) . " = " . $this->parseValue(for_v);
                }
                let whereStr = implode(op, op_arr);
                break;
        }
        return "( " . whereStr . " )";
    }

    /**
     * 字段名分析
     * @access protected
     * @param string key
     * @return string
     */
    protected function parseKey(key) {
        return key;
    }

    /**
     * value分析
     * @access protected
     * @param mixed $value
     * @return string
     */
    protected function parseValue(parse_string = null) {
        if ("string" == typeof parse_string) {
            let parse_string =  "'" . $this->escapeString(parse_string) . "'";
        } elseif (isset(parse_string[0]) && isset(parse_string[1]) && "string" == typeof parse_string[0] && strtolower(parse_string[0]) == "exp") {
            let parse_string = $this->escapeString(parse_string[1]);
        } elseif ("array" == typeof parse_string) {
            var for_k = null, for_v = null;
            for for_k, for_v in parse_string {
                let parse_string[for_k] = $this->parseValue(for_v);
            }
        } elseif (is_bool(parse_string)) {
            let parse_string = parse_string ? "1" : "0";
        } elseif (is_null(parse_string)) {
            let parse_string = "null";
        }
        return parse_string;
    }

    /**
     * SQL指令安全过滤
     * @access public
     * @param string $str SQL字符串
     * @return string
     */
    public function escapeString(str) {
        return addslashes(str);
    }

    /**
     * @node_name 开启事务
     */
    public function beginTransaction(){
        $this->connection()->beginTransaction();
    }

    /**
     * @node_name 回滚事务
     */
    public function rollBack(){
        $this->connection()->rollBack();

    }

    /**
     * @node_name 提交事务
     */
    public function commit (){

        $this->connection()->commit();
    }


}