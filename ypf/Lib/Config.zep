namespace Ypf\Lib;

class Config {

    public static $config = [];
    public static $path = [];
    
    protected static $instances = null;

    public function __construct(init_args = null) {
     	var args = func_get_args();
     	if(!empty args) {
            var for_v = null;
            for for_v in args {
     			$this->load(for_v);
     		}
     	}
     	//if(!empty init_args && "array" == typeof init_args) {
        //    var for_v = null;
        //    for for_v in init_args {
        //        var_dump(for_v);
     	//		$this->load(for_v);
     	//	}
     	//}
     	let self::$instances = $this;
	 }

	public function load(path) {
		if(is_file(path)){
		    return self::parseFile(path);
		}
		var for_data = null, config_file = null, config_name;
		let for_data = glob(path. "/*.conf");
		for config_file in for_data {
        	let self::$path[] = path;
            let config_name = basename(config_file, ".conf");
            let self::$config[config_name] = self::parseFile(config_file);
        }
        let for_data = glob(path. "/*.php");
        for config_file in for_data {
            let self::$path[] = path;
            let config_name = basename(config_file, ".php");
            let self::$config[config_name] = require(config_file);
        }
	}

    protected static function parseFile(config_file) {
        var config = parse_ini_file(config_file, true);
        if (!is_array(config) || empty config ) {
            throw new \Exception("Invalid configuration format");
        }
        return config;
    }

    public static function getInstance() {
        return self::$instances;
    }

    public function get(uri) {
        var node = self::$config;
        var paths = explode(".", uri);
        var path;
        while ("array" == typeof paths && !empty(paths)) {
            let path = array_shift(paths);
            if (!isset node[path] ) {
                return null;
            }
            let node = node[path];
        }
        return node;
    }

    public function getAll() {
         var copy = self::$config;
         return copy;
    }

	public static function clear() {
		 let self::$config = [];
	}


}
