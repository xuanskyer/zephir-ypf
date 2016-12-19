namespace Ypf\Lib;

class Response {
	private $headers = [];
	private $level = 0;
	private $output;

    public function addHeader(header) {
		let $this->headers[] = header;
	}

	public function redirect(url, status = 302) {
		header("Status: " . status);
		header("Location: " . str_replace(["&amp;", "\n", "\r"], ["&", "", ""], url));
		exit();
	}

	public function setCompression(level) {
		let $this->level = level;
	}

	public function setOutput(output) {
		let $this->output = output;
	}

	public function getOutput() {
		return $this->output;
	}

    private function compress(data, level = 0) {
	    var encoding = "";
		if (isset $_SERVER["HTTP_ACCEPT_ENCODING"]  && (strpos($_SERVER["HTTP_ACCEPT_ENCODING"], "gzip") !== false)) {
			let encoding = "gzip";
		}
		if (isset $_SERVER["HTTP_ACCEPT_ENCODING"]  && (strpos($_SERVER["HTTP_ACCEPT_ENCODING"], "x-gzip") !== false)) {
			let encoding = "x-gzip";
		}

		if ( empty encoding) {
			return data;
		}

		if (!extension_loaded("zlib") || ini_get("zlib.output_compression")) {
			return data;
		}

		if (headers_sent()) {
			return data;
		}

		if (connection_status()) {
			return data;
		}

		$this->addHeader("Content-Encoding: "  . encoding);
		return gzencode(data, level);
	}

    public function output() {
		if ($this->output) {
		    var out_put;
			if ($this->level) {
				let out_put = $this->compress($this->output, $this->level);
			} else {
				let out_put = $this->output;
			}
            var_dump("out_put:");
			if (!headers_sent()) {

			    var for_value = null;
			    for for_value in $this->headers  {
					header(for_value, true);
				}
			}

			echo out_put;
		}
	}
}
