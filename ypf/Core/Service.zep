namespace Ypf\Core;

abstract class Service
{
    public static $container;

    public function __construct()
    {
        let self::$container = \Ypf\Ypf::getContainer();
    }


    public function __set(name, value) {
        let self::$container[name] = value;
    }

    public function __get(name)
    {
        return self::$container[name];
    }
}
