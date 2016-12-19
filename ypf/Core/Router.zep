namespace Ypf\Core;
use Ypf\Lib\Request;
class Router extends Controller {

    const VARIABLE_REGEX = "~\\{\\s* ([a-zA-Z][a-zA-Z0-9_]*) \\s*(?:: \\s* ([^{}]*(?:\\{(?-1)\\}[^{}]*)*))?\\}~x";
    const DEFAULT_DISPATCH_REGEX = "[^/]+";
    private static $request = null;
    protected adapter = null;

    public function setAdapter(var adapter) {
        let this->adapter = adapter;
    }

    private function parse(route_url = "") {

        var matches = null, e = null;

        var res_preg_match_all = null;
        try{

            let res_preg_match_all = preg_match_all(
                self::VARIABLE_REGEX,
                route_url,
                matches,
                PREG_OFFSET_CAPTURE | PREG_SET_ORDER
            );

        }catch \Exception, e {
            var_dump("ypf inner error !-_-!!");
            var_dump(e);
        }
        if (!res_preg_match_all) {
            return [route_url];
        }
        var offset = 0;
        var routeData = [];
        var  for_v = null;
        if("array" == typeof matches){
            for for_v in matches {
                if (isset for_v[0][1] && for_v[0][1] > offset) {
                    let routeData[] = substr(route_url, offset, for_v[0][1] - offset);
                }
                let routeData[] = [
                    for_v[1][0],
                    isset for_v[2] ? trim(for_v[2][0]) : self::DEFAULT_DISPATCH_REGEX
                ];
                let offset = for_v[0][1] + strlen(for_v[0][0]);
            }
        }
        if(offset != strlen(route_url)){
            let routeData[] = substr(route_url, offset);
        }
        return routeData;
    }

    public function index(var request_obj = null){
        if(!empty request_obj){
            $this->setAdapter( request_obj );
        }else{
            $this->setAdapter( new Request() );
        }
        var adapter_set = "set";
        var adapter_setAll = "setAll";

        if(empty $this->adapter){
            return;
        }
        var route = \Ypf\Lib\Config::getInstance()->get("router");
        var uri = $this->getUri();
        if(isset route["static"][uri]) {
            $this->adapter->{adapter_set}("route", route["static"][uri]);
        }else{
            if(isset route["variable"] && "array" == typeof route["variable"]){
                var matches = null;
                var reg_table = null;
                var res_preg = null;
                var for_k = null, for_v = null;
                for for_k, for_v in route["variable"] {

                    let reg_table = $this->buildRegexForRoute($this->parse(for_k));
                    let res_preg = preg_match("#^" . reg_table[0] . "$#", uri, matches);

                    if (res_preg > 0) {
                        var i = 0;
                        if(isset reg_table[1] && "array" == typeof reg_table[1]){
                            var for_son_k, for_son_v;
                            for for_son_k, for_son_v in reg_table[1] {
                                let i += 1;
                                let reg_table[1][for_son_k] = matches[i];
                            }
                        }
                        $this->adapter->{adapter_setAll}( array_merge($this->adapter->get, reg_table[1]) );
                        $this->adapter->{adapter_set}("route", for_v);
                        break;
                    }
                }
            }
        }

        if (isset $this->adapter->get["route"] ) {
            return $this->action($this->adapter->get["route"]);
        }
    }

    private function buildRegexForRoute(routeData) {
        var regex = "", for_v = null;
        var variables = [];
        var varName, regexPart;

        for for_v in routeData {
            if ("string" == typeof for_v) {
                let regex .= preg_quote(for_v, "~");
                continue;
            }

            let varName = for_v[0];
            let regexPart = for_v[1];

            let variables[varName] = varName;
            let regex .= "(" . regexPart . ")";
        }

        return [regex, variables];
    }

    private function getUri() {
        var uri = "";
        if(isset _SERVER["PATH_INFO"] && !empty _SERVER["PATH_INFO"] ) {
            let uri = _SERVER["PATH_INFO"];
        }elseif(isset(_SERVER["REQUEST_URI"])) {
            let uri = parse_url(str_replace(_SERVER["SCRIPT_NAME"], "" ,_SERVER["REQUEST_URI"]), PHP_URL_PATH);
            let uri = rawurldecode(uri);
        }elseif (isset _SERVER["PHP_SELF"] ) {
            let uri = str_replace(_SERVER["SCRIPT_NAME"], "", _SERVER["PHP_SELF"]);
        }
        let uri = preg_replace(["#\\.[\\s./]*/#", "#//+#"], "/", uri);
        return uri;
    }

}
