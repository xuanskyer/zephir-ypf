namespace Ypf\Lib;

class Log {
	private $file_handle;
	private $record_level = 0;
	private static $levels = ["INFO", "WARN", "DEBUG", "ERROR"];

	public function __construct(filename) {
		var file = filename;
		let $this->file_handle = fopen(file, "a");
	}

	public function __destruct() {
		if( is_resource($this->file_handle) ) {
		    fclose($this->file_handle);
        }
	}

	public function SetLevel(level) {
		let $this->record_level = level;
	}

	private function write(level, message) {
		if ( level >= $this->record_level){
		    fwrite($this->file_handle, date("Y-m-d G:i:s") . "- [" . self::$levels[level] . "] - " . print_r(message, true) . "\n");
		}
	}

	public function Error(message) {
		$this->write(3, message);
	}

	public function Debug(message) {
		$this->write(2, message);
	}

	public function Warn(message) {
		$this->write(1, message);
	}

	public function Info(message) {
		$this->write(0, message);
	}	

}