namespace Ypf;
use Ypf\Core\Router;
use Ypf\Core\View;
use Ypf\Lib\Request;
use Ypf\Lib\Config;
use Ypf\Lib\Load;
use Ypf\Lib\DatabaseV5;
use Ypf\Lib\Log;
class Ypf
{

    const VERSION                   = "0.0.2";
    const CONNECTOR                 = "\\";
    private $container              = [];
    protected static $ypf_settings  = [];
    private $pre_action             = [];
	protected static $instances     = null;

    protected adapter = null;

    public function setAdapter(var adapter) {
        let this->adapter = adapter;
    }
    public static function say()
    {
        echo "hello world!";
    }

    public static function autoload(var className) {
        var thisClass = str_replace(__NAMESPACE__. Ypf::CONNECTOR, "", __CLASS__);
        var baseDir ;
        if isset self::$ypf_settings["root"] {
            let baseDir = self::$ypf_settings["root"];
        }else{
            let baseDir = "";
        }
        let className = ltrim(className, Ypf::CONNECTOR);
        var fileName = baseDir;
        var name_space = "";
        var lastNsPos = strripos(className, Ypf::CONNECTOR);
        if lastNsPos {
            let name_space = substr(className, 0, lastNsPos);
            let className = substr(className, lastNsPos + 1);
            let fileName = fileName . str_replace(Ypf::CONNECTOR, DIRECTORY_SEPARATOR, name_space) . DIRECTORY_SEPARATOR;
        }

        let fileName = fileName . str_replace('_', DIRECTORY_SEPARATOR, $className) . ".php";

        if (file_exists(fileName)) {
            require fileName;
        }else{
            var_dump(fileName . " not found!!");
        }
    }

    public function __construct(var settings) {
        if("array" != typeof settings || !isset settings["root"] || empty(settings["root"])){
            echo "please set config : 'root' ";
            return;
        }
        if(!isset settings["config_path"] || empty(settings["config_path"])){
            let settings["config_path"] =    settings["root"] . "/Conf/";
        }
        if(!isset settings["view_path"] || empty(settings["view_path"])){
            let settings["view_path"] =    settings["root"] . "/View/";
        }
        let self::$ypf_settings = settings;
		spl_autoload_register(__NAMESPACE__ . "\\Ypf::autoload");

        if isset self::$ypf_settings["ERROR_HANDLE_USE_SOCKET"] &&  true == self::$ypf_settings["ERROR_HANDLE_USE_SOCKET"] {
            self::registerSocketErrorHandle();
        }elseif isset self::$ypf_settings["ERROR_HANDLE_USE_CLI"] && true == self::$ypf_settings["ERROR_HANDLE_USE_CLI"] {
            self::registerCliErrorHandle();
        }else{
            self::registerErrorHandle();
        }

		let self::$instances = $this;
    }

    public static function registerSocketErrorHandle() {

        if(isset self::$ypf_settings["error_handle_open"] && self::$ypf_settings["error_handle_open"]){
            var error_handle_obj;
            let error_handle_obj = new \Ypf\Lib\ErrorHandle(self::$ypf_settings);
            register_shutdown_function([error_handle_obj, "Shutdown"]);
            set_error_handler([error_handle_obj, "Error"]);
            set_exception_handler([error_handle_obj, "Exception"]);
        }
    }

    public static function registerCliErrorHandle() {
        if(isset self::$ypf_settings["error_handle_open"] && self::$ypf_settings["error_handle_open"]){
            var error_handle_obj;
            let error_handle_obj = new \Ypf\Lib\ErrorHandleCli(self::$ypf_settings);
            register_shutdown_function([error_handle_obj, "Shutdown"]);
            set_error_handler([error_handle_obj, "Error"]);
            set_exception_handler([error_handle_obj, "Exception"]);
        }
    }

    public static function registerErrorHandle() {
        if(isset self::$ypf_settings["error_handle_open"] && self::$ypf_settings["error_handle_open"]){
            var error_handle_obj;
            let error_handle_obj = new \Ypf\Lib\ErrorHandle(self::$ypf_settings);
            register_shutdown_function([error_handle_obj, "Shutdown"]);
            set_error_handler([error_handle_obj, "Error"]);
            set_exception_handler([error_handle_obj, "Exception"]);
        }
    }

    public static function getInstance() {
        return self::$instances;
    }

    public static function getContainer() {
        return self::$instances->container;
    }

    public function addPreAction(pre_action, args = []) {
        let $this->pre_action[] = [ "action"  : pre_action, "args" : args ];
        return $this;
    }


    public function execute(action, args = []) {
        var class_name, method;
        if ("array" == typeof action && isset action[0] && isset action[1]) {
            let class_name = action[0];
            let method = action[1];
        }else{
            var pos = strrpos(action, "\\");
            let class_name = substr(action, 0, pos);
            let method = substr(action, pos + 1);
        }
        if(class_exists(class_name) && is_callable([class_name, method])) {
            var class_obj;
            let class_obj = new {class_name}();
            return call_user_func_array([class_obj, method], args);
        }else{
            throw new \Exception("Unable to load action: " . action[class_name->{method}]);
        }
    }

    public function disPatch(action = [], args = []) {

        var result, pre;
        for pre in $this->pre_action {
            if(isset pre["action"] && isset pre["args"]) {
                let result = $this->execute(pre["action"], pre["args"]);
                if (result) {
                    let action = result;
                    break;
                }
            }
        }
        while (action) {
            let action = $this->execute(action, args);
        }

    }

    public function set(var name, var value) {
        return $this->__set(name, value);
    }

    public function __set(var name, var value) {
        let $this->container[name] = value;
    }

    public function get(var name) {
		return $this->__get(name);
	}

    public function __get(name) {
        return $this->container[name];
    }

    public function __isset(name) {
        return isset($this->container[name]);
    }

    public function __unset(name) {
        unset($this->container[name]);
    }

    public function router(){
        var request_obj;
        let request_obj = new Request();
        $this->set("request", request_obj);

        $this->setAdapter( new Router() );
        var adapter_method = "index";
        if(!empty $this->adapter){
            return $this->adapter->{adapter_method}(request_obj);
        }else{
            echo "初始化路由失败：" . __METHOD__;
        }
    }

    //应用初始化运行
    public function run(){
        //注册配置对象到容器
        if(isset self::$ypf_settings["container_setting"]
            && "array" == typeof self::$ypf_settings["container_setting"]
            && !empty(self::$ypf_settings["container_setting"])
        ){
            var for_name = null, for_obj = null;
            for for_name, for_obj in self::$ypf_settings["container_setting"] {
                if(!$this->__isset(for_name) && !empty(for_obj)){
                    $this->set(for_name, for_obj);
                }
            }
        }
        if(!$this->__isset("config")){
            $this->set("config", new Config(self::$ypf_settings["config_path"]));
        }

        if(!$this->__isset("load")){
            var load_obj = null;
            let load_obj = new Load(self::$ypf_settings["root"]);
            load_obj->helper(["common"]);
            $this->set("load", load_obj);
        }
        if(!$this->__isset("db")){
            var config_obj = null;
            let config_obj = $this->get("config");
            $this->setAdapter( config_obj );
            var adapter_method = "get";
            var db_config = [];
            if(!empty $this->adapter){
                let db_config = $this->adapter->{adapter_method}("db.default");
            }
            $this->set("db", new DatabaseV5(db_config));
        }

        if(!$this->__isset("log")){
            var config_obj = null;
            let config_obj = $this->get("config");
            $this->setAdapter( config_obj );
            var adapter_method = "get";
            var log_config = [];
            if(!empty $this->adapter){
                let log_config = $this->adapter->{adapter_method}("default.log.LOG_FILE");
            }
            $this->set("log", new Log(log_config));
        }

        if(!$this->__isset("view")){
            var view_obj = null;
            let view_obj = new View();
            view_obj->setTemplateDir(self::$ypf_settings["view_path"]);
            $this->set("view", view_obj);
        }

        $this->router();
        $this->disPatch();
    }
}
