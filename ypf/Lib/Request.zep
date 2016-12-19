namespace Ypf\Lib;

class Request {
	public get      = [];
	public post     = [];
	public cookie   = [];
	public files    = [];
	public server   = [];


	public function __construct(clean_ignore = []) {
		let $this->get = (isset clean_ignore["get"] && clean_ignore["get"]) ? _GET : $this->clean(_GET);
		let $this->post = (isset clean_ignore["post"] && clean_ignore["post"]) ? _POST :  $this->clean(_POST);
		let $this->request = (isset clean_ignore["request"] && clean_ignore["request"]) ? _REQUEST :  $this->clean(_REQUEST);
		let $this->cookie = (isset clean_ignore["cookie"] && clean_ignore["cookie"]) ? _COOKIE :  $this->clean(_COOKIE);
		let $this->files = (isset clean_ignore["files"] && clean_ignore["files"]) ? _FILES :  this->clean(_FILES);
		let $this->server = (isset clean_ignore["server"] && clean_ignore["server"]) ? _SERVER :  this->clean(_SERVER);
	}

    public function clean(data) {
        if ("array" == typeof data) {
            var for_key, for_value;
            for for_key, for_value in data {
                let data[$this->clean(for_key)] = $this->clean(for_value);
            }
        } elseif("string" == typeof data) {
            let data = htmlspecialchars(trim(data), ENT_COMPAT, "UTF-8");
        }

        return data;
    }

    public function isPost() {
        return strtolower($this->server["REQUEST_METHOD"]) == "post";
    }

    public function set(name = "", default_value = ""){
        if(!empty name){
            let $this->get[name] = default_value;
        }
    }

    public function setAll(values = []){
        let $this->get = values;
    }

    public function get(name, filter = null, default_value = null) {
        var value = default_value;
        if ( "array" == typeof $this->get && isset $this->get[name] ) {
            if (!is_null(filter) && function_exists(filter)) {
                let value = {filter}($this->get[name]);
            } else {
                let value = $this->get[name];
            }
        }
        return value;
    }

    public function post(name, filter = null, default_value = null) {
        var value = default_value;
        if (isset $this->post[name] ) {
            if (!is_null(filter) && function_exists(filter)) {
                let value = {filter}($this->post[name]);
            } else {
                let value = $this->post[name];
            }
        }
        return value;
    }
}
