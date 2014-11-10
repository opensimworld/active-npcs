<?

function debug_print($trace)
{
	foreach ($trace as $k=>$v)
	{
		print "<br />#$k [$v[file]:$v[line]]: <b>$v[function]</b>(<i>";
		foreach ($v[args] as $i=>$a)
		{
			if ($i) print ", ";
			print "'$a'";
		}
		print "</i>)";
	}
}



function dbquery()
{
	if (func_num_args()> 1)
	{
		$ar = func_get_args();
		$q = array_shift($ar);
		array_walk($ar, "_mescape");
		$q = vsprintf($q, $ar);
	}
	else $q = func_get_arg(0);

	if ($_REQUEST['_doDebugSQL']>0) echo "\n\n<!-- MYQ= $q -->\n\n";

	$res = &mysql_query($q);
	if (!$res)
	{
		print("<!-- <br /><b>DB error</b> for query '$q': ".mysql_Error());
		debug_print(debug_backtrace());
		exit;
	}
	return $res;
}




function dbrow()
{

	if (func_num_args()> 1)
	{
		$ar = func_get_args();
		$q = array_shift($ar);
		array_walk($ar, "_mescape");
		$q = vsprintf($q, $ar);
	}
	else $q = func_get_arg(0);


	$res= dbquery($q);
	$row = &mysql_fetch_assoc($res);
	mysql_free_result($res);
	return $row;
}

function dbrows()
{
	if (func_num_args()> 1)
	{
		$ar = func_get_args();
		$q = array_shift($ar);
		array_walk($ar, "_mescape");
		$q = vsprintf($q, $ar);
	}
	else $q = func_get_arg(0);

	$res= dbquery($q);
	$ary =array();
	while($row = mysql_fetch_assoc($res))
	{
		$ary[]=$row;
	}
	return $ary;
}


function dbrows_singlevalue()
{

	if (func_num_args()> 1)
	{
		$ar = func_get_args();
		$q = array_shift($ar);
		array_walk($ar, "_mescape");
		$q = vsprintf($q, $ar);
	}
	else $q = func_get_arg(0);


	$res= dbquery($q);
	$ary =array();
	while($row = mysql_fetch_row($res))
	{
		$ary[]=$row[0];
	}
	return $ary;
}

function dbrows_pairs()
{

	if (func_num_args()> 1)
	{
		$ar = func_get_args();
		$q = array_shift($ar);
		array_walk($ar, "_mescape");
		$q = vsprintf($q, $ar);
	}
	else $q = func_get_arg(0);

	$res= dbquery($q);
	$ary =array();
	while($row = mysql_fetch_row($res))
	{
		$ary[$row[0]]=$row[1];
	}
	return $ary;
}



function dbbegin() { dbquery("BEGIN"); }
function dbcommit() { dbquery("COMMIT"); }
function dbrollback() { dbquery("ROLLBACK"); }

function db_store_object($table, $id, $fields)
{
	$q ='';
	foreach ($fields as $f)
	{
		$val =  ($_REQUEST[$f]);
		if ($q)
			$q.=',';
		$q .= "$f='$val'";
	}
	if ($id)
	{
		dbquery("UPDATE $table SET $q WHERE id=$id");
		return $id;
	}
	else
	{
		dbquery("INSERT INTO $table SET $q");
		return dbinsertid();
	}
}

function dbinsertid(){ return mysql_insert_id(); }
function dbaffectedrows(){ return mysql_affected_rows(); }

function dbdate2ts($dbdate)
{
	list($y, $m,$d, $h, $i) = sscanf($dbdate,"%04d-%02d-%02d %d:%d");
	return mktime($h, $i, 0, $m, $d, $y, 0);
}


function arr_fields(&$array, $field)
{
	$out = array();
	foreach ($array as $a)
	{
		$out[] = $a[$field];
	}
	return $out;
}


function _mescape(&$value)
{
    $value = mysql_real_escape_string($value);
}

function quote_request()
{
	array_walk_recursive($_REQUEST, '_mescape');
}


function e($a)
{
	return mysql_real_escape_string($a);
}

