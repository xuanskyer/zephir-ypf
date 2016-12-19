namespace Ypf\Lib;

class Load {

	private static $base = "";

    public function __construct(base = "")
    {
    	let self::$base = base;
    }

	public function library(library_name, params = null, object_name = null) {
		if (empty library_name ) {
			return $this;
		} elseif ( "array" == typeof library_name) {
		    var for_k, for_v;
		    for for_k, for_v in library_name {
				if ("integer" == typeof for_k) {
					$this->library(for_v, params);
				} else {
					$this->library(for_k, params, for_v);
				}
			}
			return $this;
		}
		$this->load_class(library_name, params, object_name);
		return $this;
	}

	public function helper(params = []) {
		var helpers, args = func_get_args();
		if(func_num_args() == 1 && isset args[0] && "array" == typeof args[0] ) {
			let helpers = args[0];
		}else{
			let helpers = args;
		}
		if("array" == typeof params && !empty(params)){
		    let helpers = array_unique(array_merge(helpers, params));
		}
		var file_name = null, for_v = null;
		for for_v in helpers  {
			let for_v = str_replace(".php", "", trim(for_v, "/"));
			let file_name = self::$base . "/Helper/" . for_v . ".php";
			if(!is_file(file_name)){
			    trigger_error("Unable to load the helper file: " . file_name);
            }
			require(file_name);
		}
	}

	protected function load_class(class_name, params = null, object_name = null) {

		let class_name = str_replace(".php", "", trim(class_name, "/"));
        var sub_dir, last_slash = strrpos(class_name, "/");

		if (last_slash !== false) {
		    let last_slash += 1;
			let sub_dir = substr(class_name, 0, last_slash);
			let class_name = substr(class_name, last_slash);
		} else {
			let sub_dir = "";
		}

		let class_name = ucfirst(class_name);
		var subclass ;
		let subclass= self::$base . "/Library/" . sub_dir . class_name . ".php";
		require(subclass);

		if (empty object_name ) {
			let object_name = strtolower(class_name);
		}

		var ypf_instance = \Ypf\Ypf::getInstance();

        if (isset ypf_instance->{object_name} ) {
            trigger_error("Resource " . object_name . " already exists and is not a " . class_name . " instance.");
        }

        let ypf_instance->{object_name} = empty params ? new {class_name}(params) : new {class_name}();

	}
}
