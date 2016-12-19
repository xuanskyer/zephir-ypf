namespace Ypf\Lib;

class ErrorHandleCli
{
    protected static $error_handle_level  = 0;

    public function __construct(var error_settings) {
        if ("array" == typeof error_settings) && isset error_settings["error_handle_level"] {
            let self::$error_handle_level = error_settings["error_handle_level"];
        }else{
            let self::$error_handle_level = E_ALL ^ E_WARNING ^ E_NOTICE;
        }

    }

    public function Shutdown() {
        var_dump("ypf-cli shutdown:");

    }

    public function Error(var error_type, message, file, line) {
        var valid_type = 0;
        if ("integer" == typeof error_type) && ("integer" == typeof self::$error_handle_level) {
            let valid_type = error_type & self::$error_handle_level;
        }else{
            let valid_type = 0;
        }
        if valid_type != error_type { return; };
        var_dump("ypf-cli error:");
        var error_info            = [];
        let error_info["type"]    = self::FriendlyErrorType(error_type);
        let error_info["message"] = message;
        let error_info["file"]    = file;
        let error_info["line"]    = line;
        var_dump(error_info);

    }

    public function Exception(exception) {
        if self::$error_handle_level & E_ERROR {

            var_dump("ypf-cli exception:");
            var exception_info            = [];
            let exception_info["message"] = exception->getMessage();
            let exception_info["code"]    = exception->getCode();
            var_dump(exception_info);

        }
    }

    public static function FriendlyErrorType(type) {
        switch(type) {
            case E_ERROR: // 1 //
                return "E_ERROR";
            case E_WARNING: // 2 //
                return "E_WARNING";
            case E_PARSE: // 4 //
                return "E_PARSE";
            case E_NOTICE: // 8 //
                return "E_NOTICE";
            case E_CORE_ERROR: // 16 //
                return "E_CORE_ERROR";
            case E_CORE_WARNING: // 32 //
                return "E_CORE_WARNING";
            case E_CORE_ERROR: // 64 //
                return "E_COMPILE_ERROR";
            case E_CORE_WARNING: // 128 //
                return "E_COMPILE_WARNING";
            case E_USER_ERROR: // 256 //
                return "E_USER_ERROR";
            case E_USER_WARNING: // 512 //
                return "E_USER_WARNING";
            case E_USER_NOTICE: // 1024 //
                return "E_USER_NOTICE";
            case E_STRICT: // 2048 //
                return "E_STRICT";
            case E_RECOVERABLE_ERROR: // 4096 //
                return "E_RECOVERABLE_ERROR";
            case E_DEPRECATED: // 8192 //
                return "E_DEPRECATED";
            case E_USER_DEPRECATED: // 16384 //
                return "E_USER_DEPRECATED";
        }
        return "";
    }
}