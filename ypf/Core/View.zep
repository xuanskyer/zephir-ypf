namespace Ypf\Core;

class View
{
	private template_dir = [];
	static protected $data = [];
	private $output;

	public function assign(name, value)
	{
		if ("array" == typeof name) {
		    var assign_key, assign_value;
		    for assign_key, assign_value in name {
				let self::$data[assign_key] = assign_value;
			}
		}elseif("string" == typeof name) {
			let self::$data[name] = value;
		}else {
			throw new \Exception(name . " only accept string or array");
		}

	}

	public function fetcher(template, display = false)
	{
		if("array" == typeof $this->template_dir && !empty $this->template_dir){
		    var for_value = null, template_file = null;
		    for for_value in $this->template_dir {
		        let template_file = for_value . template;
                if(!is_file(template_file)) {
                   trigger_error("Error: Could not load template " . template_file  . "!");
                }else{
                    extract(self::$data);
                    ob_start();
                    require(template_file);
                    let $this->output  = ob_get_contents();
                    ob_end_clean();
                   if (display) {
                       echo $this->output;
                   } else {
                       return $this->output;
                   }
                }
		    }
		}

	}

	public function display(template)
	{
        $this->fetcher(template, true);
	}

	public function setTemplateDir(template_dir)
	{
	    if(empty template_dir){
	        return ;
        }
	    if("array" != typeof template_dir){
            array_push($this->template_dir, preg_replace("#(\\w+)(/|\\\\){1,}#", "$1$2", rtrim(template_dir, "/\\")) . DIRECTORY_SEPARATOR);
        }else{
            var for_key, for_value;
            for for_key, for_value in template_dir {
                let $this->template_dir[for_key] = preg_replace("#(\\w+)(/|\\\\){1,}#", "$1$2", rtrim(for_value, "/\\")) . DIRECTORY_SEPARATOR;
            }
        }

	}


    public function __call(method_call = "", args = []) {
        if("fetch" == method_call){
            var template = null, display = false;
            if(isset args[0]){
                let template = args[0];
            }
            if(isset args[1]){
                let display = args[1];
            }

            return $this->fetcher(template, display);
        }
    }
}
