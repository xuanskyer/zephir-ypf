<?php

$test = = <<<'REGEX'
~\{
\s* ([a-zA-Z][a-zA-Z0-9_]*) \s*
(?:
: \s* ([^{}]*(?:\{(?-1)\}[^{}]*)*)
)?
\}~x
REGEX;

var_dump($test);
