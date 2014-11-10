<?php

ini_set('short_open_tag', 'On');

require('sql.inc.php');
$_fbDbName = 'databasename';
$_fbDbUser = 'databaseuser'; // Change these!
$_fbDbPass = 'databasepassword';

$request->script = "$request->webroot/";

/* Database init */
$maintenance =0;
if ($maintenance || !@mysql_connect("localhost", "$_fbDbUser", "$_fbDbPass"))
{
	header("Pragma: no-cache");
	header("Expires: 0");
	
	echo("<h1>Performing maintenance</h1> <b>We will be back with you shortly. Please check back in a few minutes. We apologize for the inconvenience.");
	exit;
}

mysql_select_db("$_fbDbName");
mysql_query("SET NAMES utf8");

header("Pragma: no-cache");
header("Expires: 0");
header("Content-type: text/html;charset=utf-8");
header('P3P:CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"');



global $cityId;


function genRoute($cur, $tgt, $path, &$foundPaths, $depth=0)
{
	global $cityId;
	global $request;
	global $_linkCache;


	if ($depth > 16) return;


	$res = dbrows("SELECT * FROM links WHERE (a=%d or b=%d) AND city_id=%d  ", $cur, $cur, $cityId);
	foreach ($res as $r)
	{
		$nxt = $r[a] == $cur ? $r[b] : $r[a];

		if ( strstr($path, ":$nxt:")) // already in
		{
		}
		else
		{
			if ($nxt == $tgt)
			{
				$foundPaths[] = "$path$nxt:";
				return true;
			}
			else
			{
				genRoute($nxt, $tgt, "$path$nxt:", $foundPaths, $depth+1);
			}
		}
	}

}

function findShortestPath($a, $b)
{
	global $cityId;
	$path = ":$a:";
	$foundPaths = [];
	genRoute($a, $b, $path, $foundPaths, 0);

	if (!count($foundPaths)) return "";

	$min = 9999999;
	$bestpath = "";
	foreach ($foundPaths as $k=>$p)
	{
		if (strlen($p) < $min)
		{
			$min =  strlen($p);
			$bestpath = $p;
		}
	}

	return $bestpath;
}



$out = "";

$cityKey = $_REQUEST[cityKey];

$res = dbrow("SELECT * FROM city_keys WHERE ckey='%s'", $cityKey);

if (!$res[city_id])
{
	die("Bad city key $cityKey");
}

$cityId = $res[city_id];

if  ($_REQUEST[act] == 'updateNodes')
{

	$postdata = file_get_contents("php://input"); 
	$d = explode("|", $postdata);
	dbquery("DELETE FROM waypoints WHERE city_id=%d", $cityId);
	$num =0;

	for ($i=0; $i < count($d); $i+= 4)
	{
		if ($d[$i])
		{
			dbquery("REPLACE INTO waypoints SET vx=%f, vy=%f, vz=%f, city_id=%d, id=%d, title='%s'", $d[$i+0], $d[$i+1], $d[$i+2], $cityId,$num, $d[$i+3]);
		}
		$num++;
	}
	$out = "OK $num";
}
else if ($_REQUEST[act] == "updateLinks")
{
	$postdata = file_get_contents("php://input"); 
	$d = explode(",", $postdata);

	dbquery("DELETE FROM links WHERE city_id=%d", $cityId);
	$num =0;
	for ($i=0; $i < count($d); $i+= 2)
	{
		dbquery("REPLACE INTO links SET city_id=%d, a=%d, b=%d", $cityId, $d[$i], $d[$i+1]);
		$num++;
	}

	$res = dbrows("delete FROM routes WHERE city_id=%d ", $cityId);
	$out = "OK $num";
}
else if ($_REQUEST[act] == 'getPath')
{
	$a = $_REQUEST[src];
	$b = $_REQUEST[tgt];

	$res = dbrows("SELECT * FROM waypoints WHERE city_id=%d AND id='%d'", $cityId, ($b));
	if (!count($res))
	{
		$path = "unknown";
	}
	else if ($a == $b)
	{
		$path = ":$a:";
	}
	else
	{
		$b = $res[0][id];
		$tgt = $res[0][title];

		$res = dbrow("SELECT * FROM routes WHERE city_id=%d AND  (( a=%d and b=%d))", $cityId, $a, $b, $a, $b);
		if ($res[city_id])
		{
			$path = $res[path];
		}
		else
		{
			$path = findShortestPath($a, $b);
			if ($path != "")
			{
				dbquery("INSERT INTO routes SET city_id=%d, a=%d, b=%d, path='%s'", $cityId, $a, $b, $path);
			}
		}
		if ($path == "") $path = "empty";
	}


	$out = "$path|$tgt";
}
else if ($_REQUEST[act] == 'getPathOld')
{
	$a = $_REQUEST[src];
	$tgt = $_REQUEST[tgt];
	$res = dbrows("SELECT * FROM waypoints WHERE city_id=%d AND title='%s'", $cityId, trim($tgt));
	if (!count($res) || $tgt == '')
	{
		$path = "unknown";
	}
	else
	{
		$b = $res[0][id];

		$res = dbrow("SELECT * FROM routes WHERE city_id=%d AND  (( a=%d and b=%d))", $cityId, $a, $b, $a, $b);
		if ($res[city_id])
		{
			$path = $res[path];
		}
		else
		{
			$path = findShortestPath($a, $b);
			if ($path != "")
			{
				dbquery("INSERT INTO routes SET city_id=%d, a=%d, b=%d, path='%s'", $cityId, $a, $b, $path);
			}
		}
		if ($path == "") $path = "empty";
	}


	$out = "$path|$tgt";
}


echo $out;


