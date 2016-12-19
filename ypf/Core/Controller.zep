namespace Ypf\Core;

abstract class Controller
{
	public static $container = null;
		
	public function __construct()
	{
		let self::$container = \Ypf\Ypf::getContainer();
	}
	
	protected function action(action, args = [])
	{
		return \Ypf\Ypf::getInstance()->execute(action, args);
	}
	
	public function __set(name, value) {
		let self::$container[name] = value;
	}

    public function __get(name)
    {
        return self::container[name];
    }
}
