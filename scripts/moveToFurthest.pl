#perl
#ver 1.01
#author : Seneca Menard

#(1-24-12 bugfix) : now supports viewport roll.  yay.
#(1-26-11 feature) : now supports edited workplanes.  :)
#(2-2-12 feature) : now supports multiple layers, item moves, item references
#(7-12-13 feature) : put in "forceUV" option to force uv edits even if you're in the 3d view (handy for macros)
#(1-10-14 fix) : put in actr storage

#setup
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my @foregroundLayers = lxq("query layerservice layers ? foreground");
my $moveDir = "up";
my $moveDirTableVal = 0;
my $lesserOrGreater = "lesser";
my $horizontalVertical = 0;
my $eachGroup = 0;
my $eachElement = 0;
my %elems;
my $skipReselectionSub = 0;
my $forceUV = 0;

#script args:
foreach my $arg (@ARGV){
	if		($arg eq "up")			{$moveDir = "up";		$moveDirTableVal = 0;	}
	elsif	($arg eq "right")		{$moveDir = "right";	$moveDirTableVal = 1;	}
	elsif	($arg eq "down")		{$moveDir = "down";		$moveDirTableVal = 2;	}
	elsif	($arg eq "left")		{$moveDir = "left";		$moveDirTableVal = 3;	}
	elsif	($arg eq "horizontal")	{$horizontalVertical = 1;						}
	elsif	($arg eq "vertical")	{$horizontalVertical = 1;						}
	elsif	($arg eq "eachGroup")	{$eachGroup = 1;								}
	elsif	($arg eq "eachElement")	{$eachElement = 1;								}
	elsif	($arg eq "forceUV")		{$forceUV = 1;									}
}


#-----------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO6 FIX))
#-----------------------------------------------------------------------------------
#sets the ACTR preset
my $seltype;
my $selAxis;
my $selCenter;
my $actr = 1;

if   ( lxq( "tool.set actr.auto ?") eq "on")			{	$seltype = "actr.auto";			}
elsif( lxq( "tool.set actr.select ?") eq "on")			{	$seltype = "actr.select";		}
elsif( lxq( "tool.set actr.border ?") eq "on")			{	$seltype = "actr.border";		}
elsif( lxq( "tool.set actr.selectauto ?") eq "on")		{	$seltype = "actr.selectauto";	}
elsif( lxq( "tool.set actr.element ?") eq "on")			{	$seltype = "actr.element";		}
elsif( lxq( "tool.set actr.screen ?") eq "on")			{	$seltype = "actr.screen";		}
elsif( lxq( "tool.set actr.origin ?") eq "on")			{	$seltype = "actr.origin";		}
elsif( lxq( "tool.set actr.parent ?") eq "on")			{	$seltype = "actr.parent";		}
elsif( lxq( "tool.set actr.local ?") eq "on")			{	$seltype = "actr.local";		}
elsif( lxq( "tool.set actr.pivot ?") eq "on")			{	$seltype = "actr.pivot";		}
elsif( lxq( "tool.set actr.pivotparent ?") eq "on")		{	$seltype = "actr.pivotparent";	}

elsif( lxq( "tool.set actr.worldAxis ?") eq "on")		{	$seltype = "actr.worldAxis";	}
elsif( lxq( "tool.set actr.localAxis ?") eq "on")		{	$seltype = "actr.localAxis";	}
elsif( lxq( "tool.set actr.parentAxis ?") eq "on")		{	$seltype = "actr.parentAxis";	}

else
{
	$actr = 0;
	lxout("custom Action Center");
	
	if   ( lxq( "tool.set axis.auto ?") eq "on")		{	 $selAxis = "auto";				}
	elsif( lxq( "tool.set axis.select ?") eq "on")		{	 $selAxis = "select";			}
	elsif( lxq( "tool.set axis.element ?") eq "on")		{	 $selAxis = "element";			}
	elsif( lxq( "tool.set axis.view ?") eq "on")		{	 $selAxis = "view";				}
	elsif( lxq( "tool.set axis.origin ?") eq "on")		{	 $selAxis = "origin";			}
	elsif( lxq( "tool.set axis.parent ?") eq "on")		{	 $selAxis = "parent";			}
	elsif( lxq( "tool.set axis.local ?") eq "on")		{	 $selAxis = "local";			}
	elsif( lxq( "tool.set axis.pivot ?") eq "on")		{	 $selAxis = "pivot";			}
	else												{	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action AXIS that I couldn't read");}

	if   ( lxq( "tool.set center.auto ?") eq "on")		{	 $selCenter = "auto";			}
	elsif( lxq( "tool.set center.select ?") eq "on")	{	 $selCenter = "select";			}
	elsif( lxq( "tool.set center.border ?") eq "on")	{	 $selCenter = "border";			}
	elsif( lxq( "tool.set center.element ?") eq "on")	{	 $selCenter = "element";		}
	elsif( lxq( "tool.set center.view ?") eq "on")		{	 $selCenter = "view";			}
	elsif( lxq( "tool.set center.origin ?") eq "on")	{	 $selCenter = "origin";			}
	elsif( lxq( "tool.set center.parent ?") eq "on")	{	 $selCenter = "parent";			}
	elsif( lxq( "tool.set center.local ?") eq "on")		{	 $selCenter = "local";			}
	elsif( lxq( "tool.set center.pivot ?") eq "on")		{	 $selCenter = "pivot";			}
	else												{ 	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action CENTER that I couldn't read");}
}


#find the viewport axis
my $viewport = lxq("query view3dservice mouse.view ?");
my $viewportType = lxq("query view3dservice view.type ? $viewport");

my @viewMatrix = queryViewportMatrix();
my @axis;
if		($moveDir eq "up")		{	@axis = ($viewMatrix[1][0],$viewMatrix[1][1],$viewMatrix[1][2]);	}
elsif	($moveDir eq "right")	{	@axis = ($viewMatrix[0][0],$viewMatrix[0][1],$viewMatrix[0][2]);	}
elsif	($moveDir eq "down")	{	@axis = (-$viewMatrix[1][0],-$viewMatrix[1][1],-$viewMatrix[1][2]);	}
elsif	($moveDir eq "left")	{	@axis = (-$viewMatrix[0][0],-$viewMatrix[0][1],-$viewMatrix[0][2]);	}

my $axis;
my $toolAxis;
my $viewportAxis;
my @xAxis = (1,0,0);
my @yAxis = (0,1,0);
my @zAxis = (0,0,1);
my $dp0 = dotProduct(\@axis,\@xAxis);
my $dp1 = dotProduct(\@axis,\@yAxis);
my $dp2 = dotProduct(\@axis,\@zAxis);
my @greatestDP_info = (0,0);

if (abs($dp0) > abs($dp1))					{	@greatestDP_info = (0,$dp0);	$toolAxis = "posX";	}
else										{	@greatestDP_info = (1,$dp1);	$toolAxis = "posY";	}
if (abs($dp2) > abs($greatestDP_info[1]))	{	@greatestDP_info = (2,$dp2);	$toolAxis = "posZ";	}
if ($greatestDP_info[1] > 0)				{	$lesserOrGreater = "greater";						}
$axis = $greatestDP_info[0];

#selection modes
if    	( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )	{	our $selMode = "vert";	}
elsif	( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )	{	our $selMode = "edge";	}
elsif	( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )	{	our $selMode = "poly";	}
else																{	die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

#build element tables
if (($forceUV == 0) && ($viewportType eq "MO3D")){
	our @firstLastElems = createPerLayerElemList($selMode,\%elems,edgeSort);
}elsif (($selMode eq "poly") && (($eachGroup == 1) || ($eachElement == 1))){
	&selectVmap;
	our @firstLastElems = createPerLayerElemList($selMode,\%elems,edgeSort);
}elsif (($selMode eq "edge") && (($eachGroup == 1) || ($eachElement == 1))){
	&selectVmap;
	our %edges;
	our @firstLastEdges = createPerLayerElemList(edge,\%edges,edgeSort);
	our @firstLastUvVerts = createPerLayerUVSelList(uvEdge,\%elems,\@foregroundLayers);
}elsif  (($eachGroup == 1) || ($eachElement == 1)){
	&selectVmap;
	our @firstLastUvVerts = createPerLayerUVSelList(uvVert,\%elems,\@foregroundLayers);
}

#3D : sort the elems and then send them to moveToFarthest sub
if (($forceUV ==  0) && ($viewportType eq "MO3D")){
	if ($selMode eq "vert"){
		#[->] : VERT : GROUPS
		if ($eachGroup == 1){
			my %touchingVerts; returnTouchingElems("vert",\%elems,\%touchingVerts);
			foreach my $layer (keys %touchingVerts){
				my $layerID = lxq("query layerservice layer.id ? $layer");
				if (@foregroundLayers > 1){lx("select.subItem {$layerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}
				foreach my $group (keys %{$touchingVerts{$layer}}){
					moveToFarthest(\@{$touchingVerts{$layer}{$group}});
				}
			}
		}
		#[->] : VERT : ALL
		else{
			foreach my $layer (sort keys %elems){
				my $layerID = lxq("query layerservice layer.id ? $layer");
				if (@foregroundLayers > 1){lx("select.subItem {$layerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}
				moveToFarthest(\@{$elems{$layer}});
			}
		}
	}elsif ($selMode eq "edge"){
		#[->] : EDGE : GROUP
		if ($eachGroup == 1){
			my %touchingEdges; returnTouchingElems("edge",\%elems,\%touchingEdges);

			foreach my $layer (keys %touchingEdges){
				my $layerID = lxq("query layerservice layer.id ? $layer");
				if (@foregroundLayers > 1){lx("select.subItem {$layerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}

				foreach my $group (keys %{$touchingEdges{$layer}}){
					my %vertList = ();
					foreach my $edge (@{$touchingEdges{$layer}{$group}}){
						my @verts = split (/[^0-9]/, $edge);
						$vertList{@verts[0]} = 1;
						$vertList{@verts[1]} = 1;
					}
					my @vertListKeys = (keys %vertList);
					moveToFarthest(\@vertListKeys);
				}
			}
		}
		#[->] : EDGE : INDIVIDUAL
		elsif ($eachElement == 1){
			foreach my $layer (sort keys %elems){
				my $layerID = lxq("query layerservice layer.id ? $layer");
				if (@foregroundLayers > 1){lx("select.subItem {$layerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}
				my %elemList;

				foreach my $edge (@{$elems{$layer}}){
					my @verts = split (/[^0-9]/, $edge);
					my @edge = (@verts[0],@verts[1]);
					moveToFarthest(\@edge);
				}
			}
		}
		#[->] : EDGE : ALL
		else{
			foreach my $layer (sort keys %elems){
				my $layerID = lxq("query layerservice layer.id ? $layer");
				if (@foregroundLayers > 1){lx("select.subItem {$layerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}
				my %vertList;

				foreach my $edge (@{$elems{$layer}}){
					my @verts = split (/[^0-9]/, $edge);
					$vertList{@verts[0]} = 1;
					$vertList{@verts[1]} = 1;
				}
				my @vertListKeys = (keys %vertList);
				moveToFarthest(\@vertListKeys);
			}
		}
	}elsif ($selMode eq "poly"){
		#[->] : POLY : GROUPS
		if ($eachGroup == 1){
			my %touchingPolys; returnTouchingElems("poly",\%elems,\%touchingPolys);

			foreach my $layer (keys %touchingPolys){
				my $layerID = lxq("query layerservice layer.id ? $layer");
				if (@foregroundLayers > 1){lx("select.subItem {$layerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}

				foreach my $group (keys %{$touchingPolys{$layer}}){
					my %vertList;
					foreach my $poly (@{$touchingPolys{$layer}{$group}}){
						my @verts = lxq("query layerservice $selMode.vertList ? $poly");
						$vertList{$_} = 1 for @verts;
					}
					my @vertListKeys = (keys %vertList);
					moveToFarthest(\@vertListKeys);
				}
			}
		}
		#[->] : POLY : INDIVIDUAL
		elsif ($eachElement == 1){
			foreach my $layer (sort keys %elems){
				my $layerID = lxq("query layerservice layer.id ? $layer");
				if (@foregroundLayers > 1){lx("select.subItem {$layerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}

				foreach my $poly (@{$elems{$layer}}){
					my @verts = lxq("query layerservice $selMode.vertList ? $poly");
					moveToFarthest(\@verts);
				}
			}
		}
		#[->] : POLY : ALL
		else{
			foreach my $layer (sort keys %elems){
				my $layerID = lxq("query layerservice layer.id ? $layer");
				if (@foregroundLayers > 1){lx("select.subItem {$layerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}
				my %vertList;

				foreach my $poly (@{$elems{$layer}}){
					my @verts = lxq("query layerservice $selMode.vertList ? $poly");
					$vertList{$_} = 1 for @verts;
				}
				my @vertListKeys = (keys %vertList);
				moveToFarthest(\@vertListKeys);
			}
		}
	}
}
#UV : use the uv align commands.
else{
	lxout("[->] : Using UV window, so firing uv align command");

	if ($selMode eq "vert"){
		#[->] : UV VERT : GROUP
		if ($eachGroup == 1){
			my %touchingUvVerts; my %touchingUvVertBBOXes; returnTouchingElems("uvVert",\%elems,\%touchingUvVerts,\%touchingUvVertBBOXes);

			foreach my $layer (keys %touchingUvVerts){
				foreach my $group (keys %{$touchingUvVerts{$layer}}){
					lx("select.drop vertex");
					foreach my $uv (@{$touchingUvVerts{$layer}{$group}}){
						my @uvInfo = split(/,/, $uv);
						lx("select.element layer:$layer type:vert mode:add index:$uvInfo[1] index3:$uvInfo[0]");
					}
					moveUVsToFarthest("stretch",\@{$touchingUvVertBBOXes{$layer}{$group}});
				}
			}
		}
		#[->] : UV VERT : ALL
		else{
			lxout("moving all");
			$skipReselectionSub = 1;
			moveUVsToFarthest("uv.align");
		}
	}elsif ($selMode eq "edge"){
		#[->] : UV EDGE : GROUP
		if ($eachGroup == 1){
			$skipReselectionSub = 1;
			my %touchingUvVerts; my %touchingUvVertBBOXes; returnTouchingElems("uvEdge",\%elems,\%touchingUvVerts,\%touchingUvVertBBOXes,\%edges);

			foreach my $layer (keys %touchingUvVerts){
				foreach my $group (keys %{$touchingUvVerts{$layer}}){
					lx("select.drop vertex");
					foreach my $uv (@{$touchingUvVerts{$layer}{$group}}){
						my @uvInfo = split(/,/, $uv);
						lx("select.element layer:$layer type:vert mode:add index:$uvInfo[1] index3:$uvInfo[0]");
					}
					moveUVsToFarthest("stretch",\@{$touchingUvVertBBOXes{$layer}{$group}});
				}
			}
			lx("select.type edge");
		}
		#[->] : UV EDGE : INDIVIDUAL
		elsif ($eachElement == 1){
			$skipReselectionSub = 1;
			moveUVsToFarthest("uv.align");
		}
		#[->] : UV EDGE : ALL
		else{
			$skipReselectionSub = 1;
			moveUVsToFarthest("uv.align");
		}
	}elsif ($selMode eq "poly"){
		#[->] : UV POLY : GROUP
		if ($eachGroup == 1){
			$skipReselectionSub = 1;
			moveUVsToFarthest("uv.align");
		}
		#[->] : UV POLY : INDIVIDUAL
		elsif ($eachElement == 1){
			$skipReselectionSub = 1;
			moveUVsToFarthest("uv.align");
		}
		#[->] : UV POLY : ALL
		else{
			$skipReselectionSub = 1;
			moveUVsToFarthest("uv.align");
		}
	}
}


#CLEANUP :

#Set the action center settings back
if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }

#restore the layer list because I had to hijack the selected layers in order to
if ((@foregroundLayers > 1) && ($skipReselectionSub != 1)){
	my $layerID = lxq("query layerservice layer.id ? @foregroundLayers[0]");
	lx("select.subItem {$layerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
	for (my $i=1; $i<@foregroundLayers; $i++){
		my $layerID = lxq("query layerservice layer.id ? @foregroundLayers[$i]");
		lx("select.subItem {$layerID} add mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
	}
	restoreSelection();
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RESTORE SELECTION SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : restoreSelection();
#NOTE : uses the hardcoded %elems hash table
#NOTE : uses the viewport type answer
sub restoreSelection{
	if (($forceUV == 0) && ($viewportType eq "MO3D")){
		foreach my $layer (keys %elems){
			if ($selMode eq "edge"){
				foreach my $elem (@{$elems{$layer}}){
					my @verts = split (/[^0-9]/, $elem);
					lx("select.element $layer $selMode add $verts[0] $verts[1]");
				}
			}else{
				foreach my $elem (@{$elems{$layer}}){
					lx("select.element $layer $selMode add $elem");
				}
			}
		}
	}else{
		foreach my $layer (keys %elems){
			if ($selMode eq "vert"){
				foreach my $uv (@{$elems{$layer}}){
					my @uvInfo = split(/,/, $uv);
					lx("select.element layer:$layer type:$selMode mode:add index:$uvInfo[1] index3:$uvInfo[0]");
				}
			}elsif ($selMode eq "edge"){
				foreach my $uv (@{$elems{$layer}}){
					my @uvInfo = split(/,/, $uv);
					lx("select.element layer:$layer type:$selMode mode:add index:$uvInfo[1] index2:[2] index3:$uvInfo[0]");
				}
			}else{
				foreach my $elem (@{$elems{$layer}}){
					lx("select.element $layer $selMode add $elem");
				}
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#MOVE UVS TO FARTHEST SUB :
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : moveUVsToFarthest(<stretch|uv.align>,\@bbox); 2
sub moveUVsToFarthest{
	if ($_[0] eq "uv.align"){
		if		($moveDir eq "up")		{lx("uv.align Up High");	}
		elsif	($moveDir eq "right")	{lx("uv.align Right High");	}
		elsif	($moveDir eq "down")	{lx("uv.align Down Low");	}
		elsif	($moveDir eq "left")	{lx("uv.align Left Low");	}
		else	{die("You didn't type in up, right, down, or left as a cvar and so I'm cancelling the script");}
	}elsif($_[0] eq "stretch"){
		my @stretchAmount = (1,1);
		my @toolCenter;

		if		($moveDir eq "up"){
			if ($horizontalVertical == 1)	{	$stretchAmount[1] = 0;	@toolCenter = ( @{$_[1]}[0] , (@{$_[1]}[3]+@{$_[1]}[1])*.5 );	}
			else							{	$stretchAmount[1] = 0;	@toolCenter = ( @{$_[1]}[0] , @{$_[1]}[3] );					}
		}elsif	($moveDir eq "right"){
			if ($horizontalVertical == 1)	{	$stretchAmount[0] = 0;	@toolCenter = ( (@{$_[1]}[2]+@{$_[1]}[0])*.5 , @{$_[1]}[3] );	}
			else							{	$stretchAmount[0] = 0;	@toolCenter = ( @{$_[1]}[2] , @{$_[1]}[3] );					}
		}elsif	($moveDir eq "down"){
			if ($horizontalVertical == 1)	{	$stretchAmount[1] = 0;	@toolCenter = ( @{$_[1]}[0] , (@{$_[1]}[3]+@{$_[1]}[1])*.5 );	}
			else							{	$stretchAmount[1] = 0;	@toolCenter = ( @{$_[1]}[0] , @{$_[1]}[1] );					}
		}elsif	($moveDir eq "left"){
			if ($horizontalVertical == 1)	{	$stretchAmount[0] = 0;	@toolCenter = ( (@{$_[1]}[2]+@{$_[1]}[0])*.5 , @{$_[1]}[3] );	}
			else							{	$stretchAmount[0] = 0;	@toolCenter = ( @{$_[1]}[0] , @{$_[1]}[3] );					}
		}

		lx("tool.viewType uv");
		lx("!!tool.set actr.auto on");
		lx("!!tool.set xfrm.stretch on");
		if ($selMode eq "poly"){lx("!!tool.xfrmDisco false");}
		lx("!!tool.setAttr center.auto cenU {$toolCenter[0]}");
		lx("!!tool.setAttr center.auto cenV {$toolCenter[1]}");
		lx("!!tool.setAttr xfrm.stretch factX {$stretchAmount[0]}");
		lx("!!tool.setAttr xfrm.stretch factY {$stretchAmount[1]}");
		lx("!!tool.setAttr xfrm.stretch factZ 1");
		lx("!!tool.doApply");
		lx("!!tool.set xfrm.stretch off");
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
##MOVETOFARTHEST SUB :
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub moveToFarthest{
	my ($verts,$layer) = @_;
	my $layerID = lxq("query layerservice layer.id ? $layer");
	my @furthestVertPos;
	my $furthestDist;
	my %vertPosTable;

	#matrix
	my @itemXfrmMatrix = getItemXfrmMatrix($layerID);
	my @wpMatrix = queryWorkPlaneMatrix_4x4();
	my @itemRefMatrix = queryItemRefMatrix();
	my @matrixTrans = @itemXfrmMatrix;
	@matrixTrans = mtxMult(\@itemRefMatrix,\@matrixTrans);
	@matrixTrans = mtxMult(\@wpMatrix,\@matrixTrans);
	my @invMatrixTrans = inverseMatrix(\@matrixTrans);

	@furthestVertPos = lxq("query layerservice vert.pos ? $$verts[0]");
	@furthestVertPos = vec_mtxMult(\@matrixTrans,\@furthestVertPos);
	$furthestDist = @furthestVertPos[$axis];

	my @bbox = (@furthestVertPos,@furthestVertPos);

	#align the group to the horizontal or vertical midpoint
	if ($horizontalVertical == 1){
		foreach my $vert (@$verts){
			my @pos = lxq("query layerservice vert.pos ? $vert");
			#matrix
			@pos = vec_mtxMult(\@matrixTrans,\@pos);
			@{$vertPosTable{$vert}} = @pos;

			if (@pos[$axis] < @bbox[$axis])		{@bbox[$axis] = @pos[$axis];	}
			if (@pos[$axis] > @bbox[$axis+3])	{@bbox[$axis+3] = @pos[$axis];	}
		}
		$furthestDist = .5 * (@bbox[$axis]+@bbox[$axis+3]);
	}

	#align the group the farthest element
	else{
		foreach my $vert (@$verts){
			my @pos = lxq("query layerservice vert.pos ? $vert");

			#matrix
			@pos = vec_mtxMult(\@matrixTrans,\@pos);
			@{$vertPosTable{$vert}} = @pos;

			if		(($lesserOrGreater eq "greater") && (@pos[$axis] > $furthestDist))	{$furthestDist = @pos[$axis];}
			elsif	(($lesserOrGreater eq "lesser") && (@pos[$axis] < $furthestDist))	{$furthestDist = @pos[$axis];}
		}
	}

	#move the verts
	foreach my $vert (@$verts){
		my @pos = @{$vertPosTable{$vert}};
		$pos[$axis] = $furthestDist;
		@pos = vec_mtxMult(\@invMatrixTrans,\@pos);
		lx("vert.move vertIndex:$vert posX:{$pos[0]} posY:{$pos[1]} posZ:{$pos[2]}");
	}
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SELECT THE PROPER VMAP  #MODO301
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub selectVmap{
	my $vmaps = lxq("query layerservice vmap.n ?");
	my %uvMaps;
	my @selectedUVmaps;
	our $finalVmap;

	lxout("-Checking which uv maps to select or deselect");

	for (my $i=0; $i<$vmaps; $i++){
		if (lxq("query layerservice vmap.type ? $i") eq "texture"){
			if (lxq("query layerservice vmap.selected ? $i") == 1){push(@selectedUVmaps,$i);}
			my $name = lxq("query layerservice vmap.name ? $i");
			$uvMaps{$i} = $name;
		}
	}

	#ONE SELECTED UV MAP
	if (@selectedUVmaps == 1){
		lxout("     -There's only one uv map selected <> $uvMaps{@selectedUVmaps[0]}");
		$finalVmap = @selectedUVmaps[0];
	}

	#MULTIPLE SELECTED UV MAPS  (try to select "Texture")
	elsif (@selectedUVmaps > 1){
		my $foundVmap;
		foreach my $vmap (@selectedUVmaps){
			if ($uvMaps{$vmap} eq "Texture"){
				$foundVmap = $vmap;
				last;
			}
		}
		if ($foundVmap != "")	{
			lx("!!select.vertexMap $uvMaps{$foundVmap} txuv replace");
			lxout("     -There's more than one uv map selected, so I'm deselecting all but this one <><> $uvMaps{$foundVmap}");
			$finalVmap = $foundVmap;
		}
		else{
			lx("!!select.vertexMap $uvMaps{@selectedUVmaps[0]} txuv replace");
			lxout("     -There's more than one uv map selected, so I'm deselecting all but this one <><> $uvMaps{@selectedUVmaps[0]}");
			$finalVmap = @selectedUVmaps[0];
		}
	}

	#NO SELECTED UV MAPS (try to select "Texture" or create it)
	elsif (@selectedUVmaps == 0){
		lx("!!select.vertexMap Texture txuv replace") or $fail = 1;
		if ($fail == 1){
			lx("!!vertMap.new Texture txuv [0] [0.78 0.78 0.78] [1.0]");
			lxout("     -There were no uv maps selected and 'Texture' didn't exist so I created this one. <><> Texture");
		}else{
			lxout("     -There were no uv maps selected, but 'Texture' existed and so I selected this one. <><> Texture");
		}

		my $vmaps = lxq("query layerservice vmap.n ? all");
		for (my $i=0; $i<$vmaps; $i++){
			if (lxq("query layerservice vmap.name ? $i") eq "Texture"){
				$finalVmap = $i;
			}
		}
	}

	#ask the name of the vmap just so modo knows which to query.
	my $name = lxq("query layerservice vmap.name ? $finalVmap");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DOT PRODUCT subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	my @array1 = @{$_[0]};
	my @array2 = @{$_[1]};
	my $dp = (	(@array1[0]*@array2[0])+(@array1[1]*@array2[1])+(@array1[2]*@array2[2])	);
	return $dp;
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : popup("What I wanna print");
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------RETURN TOUCHING ELEMENTS SUBROUTINES---------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RETURN TOUCHING ELEMS SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my %touchingVerts; returnTouchingElems("vert",\%verts,\%touchingVerts);
#REQUIRES the vmap to be already queried if working with uvs
#REQUIRES buildVmapTable sub
#REQUIRES createPerLayerElemList sub : ie a layer based selection table
#REQUIRES createPerLayerUVSelList sub : ie a layer based uv selection table
#REQUIRES findPolysNeighboringPolyVerts sub
#REQUIRES removeListFromArray sub
#REQUIRES splitUVGroups sub
#REQUIRES update2dBoundingBox sub
#NOTE : makes the referenced empty hash table be a 3 tiered hash table. (layerIndice, group#, elementList)
#NOTE : if finding uv edge groups, it'll have to do a select.convert vertex because of the "uvs ? selected" query.  :(
sub returnTouchingElems{
	#VERTEX===========
	if ($_[0] eq "vert"){
		lxout("[->] : Finding touching vert groups");
		my %vertTable;
		foreach my $layer (keys %{$_[1]}){
			my $layerName = lxq("query layerservice layer.name ? $layer");
			my %selectedVertTable;	$selectedVertTable{$_} = 1 for @{${$_[1]}{$layer}};
			my %toDoListTable = %selectedVertTable;
			my %checkedVertTable = ();
			my $roundCount = 0;
			my @vertsToCheck;

			while (keys %toDoListTable > 0){
				$roundCount++;
				@vertsToCheck = (keys %toDoListTable)[0];
				delete $toDoListTable{$vertsToCheck[0]};
				$checkedVertTable{$vertsToCheck[0]} = 1;
				push(@{$_[2]{$layer}{$roundCount}},$vertsToCheck[0]);

				while (@vertsToCheck > 0){
					my @connectedVerts = lxq("query layerservice vert.vertList ? $vertsToCheck[0]");
					foreach my $vert (@connectedVerts){
						if ($checkedVertTable{$vert} != 1){
							$checkedVertTable{$vert} = 1;
							if ($selectedVertTable{$vert} == 1){
								push(@vertsToCheck,$vert);
								delete $toDoListTable{$vert};
								push(@{$_[2]{$layer}{$roundCount}},$vert);
							}
						}
					}
					shift(@vertsToCheck);
				}
			}
		}
	}
	#EDGE=============
	elsif ($_[0] eq "edge"){
		lxout("[->] : Finding touching edge groups");
		my %edgeTable;
		foreach my $layer (keys %{$_[1]}){
			my $layerName = lxq("query layerservice layer.name ? $layer");
			my %selectedEdgeTable;	$selectedEdgeTable{$_} = 1 for @{${$_[1]}{$layer}};
			my %toDoListTable = %selectedEdgeTable;
			my %checkedEdgeTable = ();
			my $roundCount = 0;
			my @edgesToCheck = ();

			while (keys %toDoListTable > 0){
				$roundCount++;
				@edgesToCheck = (keys %toDoListTable)[0];
				delete $toDoListTable{$edgesToCheck[0]};
				$checkedEdgeTable{$edgesToCheck[0]} = 1;
				push(@{$_[2]{$layer}{$roundCount}},$edgesToCheck[0]);

				while (@edgesToCheck > 0){
					my @verts = split (/[^0-9]/, $edgesToCheck[0]);
					my @connectedVerts1 = lxq("query layerservice vert.vertList ? $verts[0]");
					my @connectedVerts2 = lxq("query layerservice vert.vertList ? $verts[1]");
					my @connectedEdges;

					foreach my $vert (@connectedVerts1){
						if ($verts[0] < $vert)	{	push(@connectedEdges,$verts[0].",".$vert);	}
						else					{	push(@connectedEdges,$vert.",".$verts[0]);	}
					}
					foreach my $vert (@connectedVerts2){
						if ($verts[1] < $vert)	{	push(@connectedEdges,$verts[1].",".$vert);	}
						else					{	push(@connectedEdges,$vert.",".$verts[1]);	}
					}

					foreach my $edge (@connectedEdges){
						if ($checkedEdgeTable{$edge} != 1){
							$checkedEdgeTable{$edge} = 1;
							if ($selectedEdgeTable{$edge} == 1){
								push(@edgesToCheck,$edge);
								delete $toDoListTable{$edge};
								push(@{$_[2]{$layer}{$roundCount}},$edge);
							}
						}
					}
					shift(@edgesToCheck);
				}
			}
		}

	}
	#POLY=============
	elsif ($_[0] eq "poly"){
		lxout("[->] : Finding touching poly groups");
		my %polyTable;
		foreach my $layer (keys %{$_[1]}){
			my $layerName = lxq("query layerservice layer.name ? $layer");
			my %selectedPolyTable;	$selectedPolyTable{$_} = 1 for @{${$_[1]}{$layer}};
			my %toDoListTable = %selectedPolyTable;
			my %checkedPolyTable = ();
			my $roundCount = 0;
			my @polysToCheck;

			while (keys %toDoListTable > 0){
				$roundCount++;
				@polysToCheck = (keys %toDoListTable)[0];
				delete $toDoListTable{$polysToCheck[0]};
				$checkedPolyTable{$polysToCheck[0]} = 1;
				push(@{$_[2]{$layer}{$roundCount}},$polysToCheck[0]);

				while (@polysToCheck > 0){
					my @polyVerts = lxq("query layerservice poly.vertList ? $polysToCheck[0]");
					my %tempPolyTable=();
					foreach my $vert (@polyVerts){
						my @vertPolyList = lxq("query layerservice vert.polyList ? $vert");
						$tempPolyTable{$_} = 1 for @vertPolyList;
					}
					my @connectedPolys = (keys %tempPolyTable);

					foreach my $poly (@connectedPolys){
						if ($checkedPolyTable{$poly} != 1){
							$checkedPolyTable{$poly} = 1;
							if ($selectedPolyTable{$poly} == 1){
								push(@polysToCheck,$poly);
								delete $toDoListTable{$poly};
								push(@{$_[2]{$layer}{$roundCount}},$poly);
							}
						}
					}
					shift(@polysToCheck);
				}
			}
		}
	}
	#UV VERT OR EDGE==========
	elsif (($_[0] eq "uvVert") || ($_[0] eq "uvEdge")){
		lxout("[->] : Finding touching uvVert groups");
		my %uvVertTable;
		foreach my $layer (keys %{$_[1]}){
			my $layerName = lxq("query layerservice layer.name ? $layer");
			my %selectedUvVertTable;	$selectedUvVertTable{$_} = 1 for @{${$_[1]}{$layer}};
			my %toDoListTable = %selectedUvVertTable;
			my %checkedUvVertTable = ();
			my $roundCount = 0;
			my @uvVertsToCheck = ();
			my %uvPosTable = ();
			my $vmapName = lxq("query layerservice vmap.name ? $finalVmap");
			buildVmapTable(@_[1],\%uvPosTable,$layer);
			if ($_[0] eq "uvEdge"){
				our %selectedEdgeTable;
				foreach my $edge (@{$_[4]{$layer}}){$selectedEdgeTable{$edge} = 1;}
			}

			while (keys %toDoListTable > 0){
				my @bleh = (keys %toDoListTable);
				$roundCount++;
				@uvVertsToCheck = (keys %toDoListTable)[0];
				delete $toDoListTable{$uvVertsToCheck[0]};
				$checkedUvVertTable{$uvVertsToCheck[0]} = 1;
				push(@{$_[2]{$layer}{$roundCount}},$uvVertsToCheck[0]);

				while (@uvVertsToCheck > 0){
					my @uvInfo = split(/,/, $uvVertsToCheck[0]);
					my @polyList = lxq("query layerservice vert.polyList ? $uvInfo[1]");

					update2dBoundingBox(	$_[3]	,	$layer	,	$roundCount	,	@{$uvPosTable{$uvInfo[0]}{$uvInfo[1]}}[0]	,	@{$uvPosTable{$uvInfo[0]}{$uvInfo[1]}}[1]);

					#for each poly, I find the neighboring poly-disco-verts that are selected and add 'em to the array.
					foreach my $poly (@polyList){
						#check neighbor disco verts
						if ((@{$uvPosTable{$uvInfo[0]}{$uvInfo[1]}}[0] == @{$uvPosTable{$poly}{$uvInfo[1]}}[0]) &&
							(@{$uvPosTable{$uvInfo[0]}{$uvInfo[1]}}[1] == @{$uvPosTable{$poly}{$uvInfo[1]}}[1])){

							my @neighborVerts = findPolysNeighboringPolyVerts($poly,$uvInfo[1]);
							foreach my $vert (@neighborVerts){
								#if in edge mode, skip unselected edges <total hack, i need to be able to query disco uv edges>
								if ($_[0] eq "uvEdge"){
									if ($uvInfo[1] < $vert){
										if ($selectedEdgeTable{$uvInfo[1].",".$vert} != 1)	{next;}
									}else{
										if ($selectedEdgeTable{$vert.",".$uvInfo[1]} != 1)	{next;}
									}
								}
								if (($selectedUvVertTable{$poly.",".$vert} == 1) && ($checkedUvVertTable{$poly.",".$vert} != 1)){
									push(@uvVertsToCheck,$poly.",".$vert);
									push(@{$_[2]{$layer}{$roundCount}},$poly.",".$vert);
									delete $toDoListTable{$poly.",".$vert};
									$checkedUvVertTable{$poly.",".$vert} = 1;
									update2dBoundingBox(	$_[3]	,	$layer	,	$roundCount	,	@{$uvPosTable{$poly}{$vert}}[0]	,	@{$uvPosTable{$poly}{$vert}}[1]);
								}
							}
						}

						#check touching disco verts
						if ((@{$uvPosTable{$uvInfo[0]}{$uvInfo[1]}}[0] == @{$uvPosTable{$poly}{$uvInfo[1]}}[0]) &&
							(@{$uvPosTable{$uvInfo[0]}{$uvInfo[1]}}[1] == @{$uvPosTable{$poly}{$uvInfo[1]}}[1])){

							if ($poly != $uvInfo[0]){
								if ($checkedUvVertTable{$poly.",".$uvInfo[1]} != 1){
									push(@uvVertsToCheck,$poly.",".$uvInfo[1]);
									push(@{$_[2]{$layer}{$roundCount}},$poly.",".$uvInfo[1]);
									delete $toDoListTable{$poly.",".$uvInfo[1]};
									$checkedUvVertTable{$poly.",".$uvInfo[1]} = 1;
									update2dBoundingBox(	$_[3]	,	$layer	,	$roundCount	,	@{$uvPosTable{$poly}{$uvInfo[1]}}[0]	,	@{$uvPosTable{$poly}{$uvInfo[1]}}[1]);
								}
							}
						}
					}
					shift(@uvVertsToCheck);
				}
			}
		}
	}
	#UV POLY==========
	elsif ($_[0] eq "uvPoly"){
		lxout("[->] : Finding touching uvPoly groups");
		foreach my $layer (keys %{$_[1]}){
			my $layerName = lxq("query layerservice layer.name ? $layer");
			our @polys = @{$_[1]{$layer}};
			&splitUVGroups;
			my $roundCount = 0;
			foreach my $key (keys %touchingUVList){
				$roundCount++;
				push(@{$_[2]{$layer}{$roundCount}},@{$touchingUVList{$key}});
				push(@{$_[3]{$layer}{$roundCount}},@{$uvBBOXList{$key}});
			}
		}
	}
	#ERROR============
	else{
		die("This subroutine was called without any arguments so I'm cancelling the script.");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD VMAP TABLE SUB :
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage buildVmapTable(\%uvListRef,\%uvPosListRef,$layer);
#builds it as : table->poly->vert data
sub buildVmapTable{
	foreach my $uv ( @{$_[0]{$_[2]}} ){
		my @uvInfo = split(/,/, $uv);
		my @polyList = lxq("query layerservice vert.polyList ? $uvInfo[1]");
		foreach my $poly (@polyList){
			my @vertList = lxq("query layerservice poly.vertList ? $poly");
			my @vmapList = lxq("query layerservice poly.vmapValue ? $poly");

			for (my $i=0; $i<@vertList; $i++){
				@{$_[1]{$poly}{$vertList[$i]}} = ($vmapList[$i*2] , $vmapList[($i*2)+1]);
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A PER LAYER ELEMENT SELECTION LIST ver 3.0! (retuns first and last elems, and ordered list for all layers)  (THIS VERSION DOES SUPPORT EDGES <and can refine the edge names>!)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my @firstLastEdges = createPerLayerElemList(edge,\%edges,edgeSort<optional>);
#also, if you want the edges to be sorted, ie store 12,24 instead of 24,12, then put "edgeSort" as arg3
sub createPerLayerElemList{
	my $hash = @_[1];
	my @totalElements = lxq("query layerservice selection ? @_[0]");
	if (@totalElements == 0){die("\\\\n.\\\\n[---------------------------------------------You don't have any @_[0]s selected and so I'm cancelling the script.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

	#build the full list
	foreach my $elem (@totalElements){
		$elem =~ s/[\(\)]//g;
		my @split = split/,/,$elem;
		if (@_[0] eq "edge"){
			if (@_[2] eq "edgeSort"){
				if ($split[1] < $split[2]){
					push(@{$$hash{@split[0]}},@split[1].",".@split[2]);
				}else{
					push(@{$$hash{@split[0]}},@split[2].",".@split[1]);
				}
			}else{
				push(@{$$hash{@split[0]}},@split[1].",".@split[2]);
			}
		}else{
			push(@{$$hash{@split[0]}},@split[1]);
		}

	}

	#return the first and last elements
	return(@totalElements[0],@totalElements[-1]);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A PER LAYER UV SELECTION LIST (only for verts and edges.  for polys, use createPerLayerElemList sub)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my @firstLastUVs = createPerLayerUVSelList(uvVert,\%uvVerts,\@layersToReportOn)
#returns two values.  ((layer,poly,vert) , (layer,poly,vert))
#NOTE : if in edge sel mode, i must convert to verts in order to run the modo query
sub createPerLayerUVSelList{
	my @firstLastUVs;
	my $type = @_[0];
	my $hashRef = @_[1];
	my $layersArrayRef = @_[2];
	my $loopCheck = 0;

	foreach my $layer (@{$_[2]}){
		my $layerName = lxq("query layerservice layer.name ? $layer");
		$loopCheck++;

		if (@_[0] eq "uvEdge"){lx("!!select.convert vertex");}
		@{@_[1]}{$layer} = [lxq("query layerservice uvs ? selected")]; #note, this puts the array ref into the hash table.  this is how you get access : @{$_[1]{$layer}}
		$_ =~ s/[\(\)]//g for @firstLastUVs,@{$_[1]{$layer}};
		if ($loopCheck == 1)			{	push(@firstLastUVs,$layer . "," . @{$_[1]{$layer}}[0]);	}
		elsif ($loopCheck == @{@_[2]})	{	push(@firstLastUVs,$layer . "," . @{$_[1]{$layer}}[-1]);}
	}
	return(@firstLastUVs);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND POLYS NEIGHBORING POLY-VERTS SUB :
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage findPolysNeighboringPolyVerts($poly,$vert)
#ie : if a poly's verts are (1,2,3,4,5,6) and you tell it to look for 4, it'll return (3,5)
sub findPolysNeighboringPolyVerts{
	my @vertList = lxq("query layerservice poly.vertList ? $_[0]");
	for (my $i=0; $i<$#vertList; $i++){	if ($vertList[$i] == $_[1]){	return($vertList[$i-1],$vertList[$i+1]);	}	}
																		return($vertList[-2],$vertList[0]);
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#REMOVE ARRAY2 FROM ARRAY1 SUBROUTINE
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub removeListFromArray{
	my $array1Copy = @_[0];
	my $array2Copy = @_[1];
	my @fullList = @$array1Copy;
	my @removeList = @$array2Copy;
	for (my $i=0; $i<@removeList; $i++){
		for (my $u=0; $u<@fullList; $u++){
			if (@fullList[$u] eq @removeList[$i]	){
				splice(@fullList, $u,1);
				last;
			}
		}
	}
	return @fullList;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SPLIT THE POLYGONS INTO TOUCHING UV GROUPS (and build the uvBBOX) modded to make sure all variables are blank and also queries vmap name.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub splitUVGroups{
	lxout("[->] Running splitUVGroups subroutine");
	our %touchingUVList = ();
	our %uvBBOXList = ();
	my %originalPolys = ();
	my %vmapTable = ();
	my @scalePolys = @polys;
	my $round = 0;
	foreach my $poly (@scalePolys){$originalPolys{$poly} = 1;}
	my $vmapName = lxq("query layerservice vmap.name ? $finalVmap");

	#---------------------------------------------------------------------------------------
	#LOOP1
	#---------------------------------------------------------------------------------------
	#[1] :	(create a current uvgroup array) : (add the first poly to it) : (set 1stpoly to 1 in originalpolylist) : (build uv list for it)
	while (@scalePolys != 0){
		#setup
		my %ignorePolys = ();
		my %totalPolyList = ();
		my @uvGroup = @scalePolys[0];
		my @nextList = @scalePolys[0];
		my $loop = 1;
		my @verts = lxq("query layerservice poly.vertList ? @scalePolys[0]");
		my @vmapValues = lxq("query layerservice poly.vmapValue ? @scalePolys[0]");
		my %vmapDiscoTable = ();
		$totalPolyList{@scalePolys[0]} = 1;
		$ignorePolys{@scalePolys[0]} = 1;

		#clear the vmapTable for every round and start it from scratch
		%vmapTable = ();
		for (my $i=0; $i<@verts; $i++){
			$vmapTable{@verts[$i]}[0] = @vmapValues[$i*2];
			$vmapTable{@verts[$i]}[1] = @vmapValues[($i*2)+1];
		}

		#build the temp uvBBOX
		my @tempUVBBOX = (999999999,999999999,-999999999,-999999999); #I'm pretty sure this'll never be capped.
		$uvBBOXList{$round} = \@tempUVBBOX;

		#put the first poly's uvs into the bounding box.
		for (my $i=0; $i<@verts; $i++){
			if ( @vmapValues[$i*2] 		< 	$uvBBOXList{$round}[0] )	{	$uvBBOXList{$round}[0] = @vmapValues[$i*2];		}
			if ( @vmapValues[($i*2)+1]	< 	$uvBBOXList{$round}[1] )	{	$uvBBOXList{$round}[1] = @vmapValues[($i*2)+1];	}
			if ( @vmapValues[$i*2] 		> 	$uvBBOXList{$round}[2] )	{	$uvBBOXList{$round}[2] = @vmapValues[$i*2];		}
			if ( @vmapValues[($i*2)+1]	> 	$uvBBOXList{$round}[3] )	{	$uvBBOXList{$round}[3] = @vmapValues[($i*2)+1];	}
		}



		#---------------------------------------------------------------------------------------
		#LOOP2
		#---------------------------------------------------------------------------------------
		while ($loop == 1){
			#[1] :	(make a list of the verts on nextlist's polys) :
			my %vertList;
			my %newPolyList;
			foreach my $poly (@nextList){
				my @verts = lxq("query layerservice poly.vertList ? $poly");
				$vertList{$_} = 1 for @verts;
			}

			#clear nextlist for next round
			@nextList = ();


			#[2] :	(make a newlist of the polys connected to the verts) :
			foreach my $vert (keys %vertList){
				my @vertListPolys = lxq("query layerservice vert.polyList ? $vert");

				#(ignore the ones that are [1] in the originalpolyList or not in the list)
				foreach my $poly (@vertListPolys){
					if (($originalPolys{$poly} == 1) && ($ignorePolys{$poly} != 1)){
						$newPolyList{$poly} = 1;
						$totalPolyList{$poly} = 1;
					}
				}
			}


			#[3] :	(go thru all the polys in the new newlist and see if their uvs are touching the newlist's uv list) : (if they are, add 'em to the uvgroup and nextlist) :
			#(build the uv list for the newlist) : (add 'em to current uvgroup array)
			foreach my $poly (keys %newPolyList){
				my @verts = lxq("query layerservice poly.vertList ? $poly");
				my @vmapValues = lxq("query layerservice poly.vmapValue ? $poly");
				my $last;

				for (my $i=0; $i<@verts; $i++){
					if ($last == 1){last;}

					for (my $j=0; $j<@{$vmapTable{@verts[$i]}}; $j=$j+2){
						#if this poly's matching so add it to the poly lists.
						if ("(@vmapValues[$i*2],@vmapValues[($i*2)+1])" eq "(@{$vmapTable{@verts[$i]}}[$j],@{$vmapTable{@verts[$i]}}[$j+1])"){
							push(@uvGroup,$poly);
							push(@nextList,$poly);
							$ignorePolys{$poly} = 1;

							#this poly's matching so i'm adding it's uvs to the uv list
							for (my $u=0; $u<@verts; $u++){
								if ($vmapDiscoTable{@verts[$u].",".@vmapValues[$u*2].",".@vmapValues[($u*2)+1]} != 1){
									push(@{$vmapTable{@verts[$u]}} , @vmapValues[$u*2]);
									push(@{$vmapTable{@verts[$u]}} , @vmapValues[($u*2)+1]);
									$vmapDiscoTable{@verts[$u].",".@vmapValues[$u*2].",".@vmapValues[($u*2)+1]} = 1;
								}
							}

							#this poly's matching, so I'll create the uvBBOX right now.
							for (my $i=0; $i<@verts; $i++){
								if ( @vmapValues[$i*2] 		< 	$uvBBOXList{$round}[0] )	{	$uvBBOXList{$round}[0] = @vmapValues[$i*2];		}
								if ( @vmapValues[($i*2)+1]	< 	$uvBBOXList{$round}[1] )	{	$uvBBOXList{$round}[1] = @vmapValues[($i*2)+1];	}
								if ( @vmapValues[$i*2] 		> 	$uvBBOXList{$round}[2] )	{	$uvBBOXList{$round}[2] = @vmapValues[$i*2];		}
								if ( @vmapValues[($i*2)+1]	> 	$uvBBOXList{$round}[3] )	{	$uvBBOXList{$round}[3] = @vmapValues[($i*2)+1];	}
							}
							$last = 1;
							last;
						}
					}
				}
			}

			#This round of UV grouping is done.  Time for the next round.
			if (@nextList == 0){
				$touchingUVList{$round} = \@uvGroup;
				$round++;
				$loop = 0;
				@scalePolys = removeListFromArray(\@scalePolys, \@uvGroup);
			}
		}
	}

	my $keyCount = (keys %touchingUVList);
	lxout("     -There are ($keyCount) uv groups");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#UPDATE 2D BOUNDING BOX SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : update2dBoundingBox(\$bboxLayerHashTable,$layer,$round,$posU,$posV);
#NOTE  : requires a layer based selection hash table.
sub update2dBoundingBox{
	#lxout("$_[0] <> $_[1] <> $_[2] <> $_[3] <> $_[4]");

	if (@{$_[0]{$_[1]}{$_[2]}} == 0){
		lxout("this bbox number doesn't exist");
		@{$_[0]{$_[1]}{$_[2]}}[0] = $_[3];
		@{$_[0]{$_[1]}{$_[2]}}[1] = $_[4];
		@{$_[0]{$_[1]}{$_[2]}}[2] = $_[3];
		@{$_[0]{$_[1]}{$_[2]}}[3] = $_[4];
	}else{
		if (@{$_[0]{$_[1]}{$_[2]}}[0] > $_[3])	{	@{$_[0]{$_[1]}{$_[2]}}[0] = $_[3];	}
		if (@{$_[0]{$_[1]}{$_[2]}}[1] > $_[4])	{	@{$_[0]{$_[1]}{$_[2]}}[1] = $_[4];	}
		if (@{$_[0]{$_[1]}{$_[2]}}[2] < $_[3])	{	@{$_[0]{$_[1]}{$_[2]}}[2] = $_[3];	}
		if (@{$_[0]{$_[1]}{$_[2]}}[3] < $_[4])	{	@{$_[0]{$_[1]}{$_[2]}}[3] = $_[4];	}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY VIEWPORT MATRIX (3x3)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @3x3Matrix = queryViewportMatrix($heading,$pitch,$bank);
#requires eulerTo3x3Matrix sub
#requires transposeRotMatrix_3x3 sub
sub queryViewportMatrix{
	my $viewport = lxq("query view3dservice mouse.view ?");
	my @viewAngles = lxq("query view3dservice view.angles ? $viewport");

	if (($viewAngles[0] == 0) && ($viewAngles[1] == 0) && ($viewAngles[2] == 0)){
		lxout("[->] : queryViewportMatrix sub : must be in uv window because it returned 0,0,0 and so i'm defaulting the matrix");
		my @matrix = (
			[1,0,0],
			[0,1,0],
			[0,0,1]
		);
		return @matrix;
	}

	@viewAngles = (-$viewAngles[0],-$viewAngles[1],-$viewAngles[2]);
	my @matrix = eulerTo3x3Matrix(@viewAngles);
	@matrix = transposeRotMatrix_3x3(\@matrix);
	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY WORKPLANE MATRIX (4x4) (will move verts at (2,2,2) in workplane space to (2,2,2) in world space)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @matrix_4x4 = queryWorkPlaneMatrix_4x4();			#queries current workplane
#USAGE2 : my @matrix_4x4 = queryWorkPlaneMatrix_4x4(@WPmem);	#can send it a stored workplane instead
#requires eulerTo3x3Matrix sub
#requires mtxMult sub
sub queryWorkPlaneMatrix_4x4{
	my @WPmem;
	if (@_ > 0){
		@WPmem = @_;
	}else{
		$WPmem[0] = lxq ("workPlane.edit cenX:? ");
		$WPmem[1] = lxq ("workPlane.edit cenY:? ");
		$WPmem[2] = lxq ("workPlane.edit cenZ:? ");
		$WPmem[3] = lxq ("workPlane.edit rotX:? ");
		$WPmem[4] = lxq ("workPlane.edit rotY:? ");
		$WPmem[5] = lxq ("workPlane.edit rotZ:? ");
	}

	my @m_wp = eulerTo3x3Matrix(-$WPmem[4],-$WPmem[3],-$WPmem[5]);

	my @matrix = (
		[1,0,0,0],
		[0,1,0,0],
		[0,0,1,0],
		[0,0,0,1]
	);

	my @matrix_mov = (
		[1,0,0,-$WPmem[0]],
		[0,1,0,-$WPmem[1]],
		[0,0,1,-$WPmem[2]],
		[0,0,0,1]
	);

	my @matrix_rot = (
		[$m_wp[0][0],$m_wp[0][1],$m_wp[0][2],0],
		[$m_wp[1][0],$m_wp[1][1],$m_wp[1][2],0],
		[$m_wp[2][0],$m_wp[2][1],$m_wp[2][2],0],
		[0,0,0,1]
	);

	@matrix = mtxMult(\@matrix_mov,\@matrix);
	@matrix = mtxMult(\@matrix_rot,\@matrix);
	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#EULER TO 3X3 MATRIX 3
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @3x3Matrix = eulerTo3x3Matrix($heading,$pitch,$bank);
sub eulerTo3x3Matrix{
	my $pi = 3.14159265358979323;
	my $heading = $_[0] * ($pi/180);
	my $pitch = $_[1] * ($pi/180);
	my $bank = $_[2] * ($pi/180);

    my $ch = cos($heading);
    my $sh = sin($heading);
    my $cp = cos($pitch);
    my $sp = sin($pitch);
    my $cb = cos($bank);
    my $sb = sin($bank);

	my $m00 = $ch*$cb + $sh*$sp*$sb;
	my $m01 = -$ch*$sb + $sh*$sp*$cb;
	my $m02 = $sh*$cp;

	my $m10 = $sb*$cp;
	my $m11 = $cb*$cp;
	my $m12 = -$sp;

	my $m20 = -$sh*$cb + $ch*$sp*$sb;
	my $m21 = $sb*$sh + $ch*$sp*$cb;
	my $m22 = $ch*$cp;

    my @matrix = (
		[$m00,$m01,$m02],
		[$m10,$m11,$m12],
		[$m20,$m21,$m22],
	);

	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#3 X 3 ROTATION MATRIX FLIP (only works on rotation-only matrices though)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage @matrix = transposeRotMatrix_3x3(\@matrix);
sub transposeRotMatrix_3x3{
	my @matrix = (
		[ @{$_[0][0]}[0],@{$_[0][1]}[0],@{$_[0][2]}[0] ],	#[a00,a10,a20,a03],
		[ @{$_[0][0]}[1],@{$_[0][1]}[1],@{$_[0][2]}[1] ],	#[a01,a11,a21,a13],
		[ @{$_[0][0]}[2],@{$_[0][1]}[2],@{$_[0][2]}[2] ],	#[a02,a12,a22,a23],
	);
	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#4 X 4 MATRIX INVERSION sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @inverseMatrix = inverseMatrix(\@matrix);
sub inverseMatrix{
	my ($m) = $_[0];
	my @matrix = (
		[$$m[0][0],$$m[0][1],$$m[0][2],$$m[0][3]],
		[$$m[1][0],$$m[1][1],$$m[1][2],$$m[1][3]],
		[$$m[2][0],$$m[2][1],$$m[2][2],$$m[2][3]],
		[$$m[3][0],$$m[3][1],$$m[3][2],$$m[3][3]]
	);

	$matrix[0][0] =  $$m[1][1]*$$m[2][2]*$$m[3][3] - $$m[1][1]*$$m[2][3]*$$m[3][2] - $$m[2][1]*$$m[1][2]*$$m[3][3] + $$m[2][1]*$$m[1][3]*$$m[3][2] + $$m[3][1]*$$m[1][2]*$$m[2][3] - $$m[3][1]*$$m[1][3]*$$m[2][2];
	$matrix[1][0] = -$$m[1][0]*$$m[2][2]*$$m[3][3] + $$m[1][0]*$$m[2][3]*$$m[3][2] + $$m[2][0]*$$m[1][2]*$$m[3][3] - $$m[2][0]*$$m[1][3]*$$m[3][2] - $$m[3][0]*$$m[1][2]*$$m[2][3] + $$m[3][0]*$$m[1][3]*$$m[2][2];
	$matrix[2][0] =  $$m[1][0]*$$m[2][1]*$$m[3][3] - $$m[1][0]*$$m[2][3]*$$m[3][1] - $$m[2][0]*$$m[1][1]*$$m[3][3] + $$m[2][0]*$$m[1][3]*$$m[3][1] + $$m[3][0]*$$m[1][1]*$$m[2][3] - $$m[3][0]*$$m[1][3]*$$m[2][1];
	$matrix[3][0] = -$$m[1][0]*$$m[2][1]*$$m[3][2] + $$m[1][0]*$$m[2][2]*$$m[3][1] + $$m[2][0]*$$m[1][1]*$$m[3][2] - $$m[2][0]*$$m[1][2]*$$m[3][1] - $$m[3][0]*$$m[1][1]*$$m[2][2] + $$m[3][0]*$$m[1][2]*$$m[2][1];
	$matrix[0][1] = -$$m[0][1]*$$m[2][2]*$$m[3][3] + $$m[0][1]*$$m[2][3]*$$m[3][2] + $$m[2][1]*$$m[0][2]*$$m[3][3] - $$m[2][1]*$$m[0][3]*$$m[3][2] - $$m[3][1]*$$m[0][2]*$$m[2][3] + $$m[3][1]*$$m[0][3]*$$m[2][2];
	$matrix[1][1] =  $$m[0][0]*$$m[2][2]*$$m[3][3] - $$m[0][0]*$$m[2][3]*$$m[3][2] - $$m[2][0]*$$m[0][2]*$$m[3][3] + $$m[2][0]*$$m[0][3]*$$m[3][2] + $$m[3][0]*$$m[0][2]*$$m[2][3] - $$m[3][0]*$$m[0][3]*$$m[2][2];
	$matrix[2][1] = -$$m[0][0]*$$m[2][1]*$$m[3][3] + $$m[0][0]*$$m[2][3]*$$m[3][1] + $$m[2][0]*$$m[0][1]*$$m[3][3] - $$m[2][0]*$$m[0][3]*$$m[3][1] - $$m[3][0]*$$m[0][1]*$$m[2][3] + $$m[3][0]*$$m[0][3]*$$m[2][1];
	$matrix[3][1] =  $$m[0][0]*$$m[2][1]*$$m[3][2] - $$m[0][0]*$$m[2][2]*$$m[3][1] - $$m[2][0]*$$m[0][1]*$$m[3][2] + $$m[2][0]*$$m[0][2]*$$m[3][1] + $$m[3][0]*$$m[0][1]*$$m[2][2] - $$m[3][0]*$$m[0][2]*$$m[2][1];
	$matrix[0][2] =  $$m[0][1]*$$m[1][2]*$$m[3][3] - $$m[0][1]*$$m[1][3]*$$m[3][2] - $$m[1][1]*$$m[0][2]*$$m[3][3] + $$m[1][1]*$$m[0][3]*$$m[3][2] + $$m[3][1]*$$m[0][2]*$$m[1][3] - $$m[3][1]*$$m[0][3]*$$m[1][2];
	$matrix[1][2] = -$$m[0][0]*$$m[1][2]*$$m[3][3] + $$m[0][0]*$$m[1][3]*$$m[3][2] + $$m[1][0]*$$m[0][2]*$$m[3][3] - $$m[1][0]*$$m[0][3]*$$m[3][2] - $$m[3][0]*$$m[0][2]*$$m[1][3] + $$m[3][0]*$$m[0][3]*$$m[1][2];
	$matrix[2][2] =  $$m[0][0]*$$m[1][1]*$$m[3][3] - $$m[0][0]*$$m[1][3]*$$m[3][1] - $$m[1][0]*$$m[0][1]*$$m[3][3] + $$m[1][0]*$$m[0][3]*$$m[3][1] + $$m[3][0]*$$m[0][1]*$$m[1][3] - $$m[3][0]*$$m[0][3]*$$m[1][1];
	$matrix[3][2] = -$$m[0][0]*$$m[1][1]*$$m[3][2] + $$m[0][0]*$$m[1][2]*$$m[3][1] + $$m[1][0]*$$m[0][1]*$$m[3][2] - $$m[1][0]*$$m[0][2]*$$m[3][1] - $$m[3][0]*$$m[0][1]*$$m[1][2] + $$m[3][0]*$$m[0][2]*$$m[1][1];
	$matrix[0][3] = -$$m[0][1]*$$m[1][2]*$$m[2][3] + $$m[0][1]*$$m[1][3]*$$m[2][2] + $$m[1][1]*$$m[0][2]*$$m[2][3] - $$m[1][1]*$$m[0][3]*$$m[2][2] - $$m[2][1]*$$m[0][2]*$$m[1][3] + $$m[2][1]*$$m[0][3]*$$m[1][2];
	$matrix[1][3] =  $$m[0][0]*$$m[1][2]*$$m[2][3] - $$m[0][0]*$$m[1][3]*$$m[2][2] - $$m[1][0]*$$m[0][2]*$$m[2][3] + $$m[1][0]*$$m[0][3]*$$m[2][2] + $$m[2][0]*$$m[0][2]*$$m[1][3] - $$m[2][0]*$$m[0][3]*$$m[1][2];
	$matrix[2][3] = -$$m[0][0]*$$m[1][1]*$$m[2][3] + $$m[0][0]*$$m[1][3]*$$m[2][1] + $$m[1][0]*$$m[0][1]*$$m[2][3] - $$m[1][0]*$$m[0][3]*$$m[2][1] - $$m[2][0]*$$m[0][1]*$$m[1][3] + $$m[2][0]*$$m[0][3]*$$m[1][1];
	$matrix[3][3] =  $$m[0][0]*$$m[1][1]*$$m[2][2] - $$m[0][0]*$$m[1][2]*$$m[2][1] - $$m[1][0]*$$m[0][1]*$$m[2][2] + $$m[1][0]*$$m[0][2]*$$m[2][1] + $$m[2][0]*$$m[0][1]*$$m[1][2] - $$m[2][0]*$$m[0][2]*$$m[1][1];

	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#4X4 x 4X4 MATRIX MULTIPLY
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @matrix = mtxMult(\@matrixMult,\@matrix);
#arg0 = transform matrix.  arg1 = matrix to multiply to that then sends the results to the cvar.
sub mtxMult{
	my @matrix = (
		[ @{$_[0][0]}[0]*@{$_[1][0]}[0] + @{$_[0][0]}[1]*@{$_[1][1]}[0] + @{$_[0][0]}[2]*@{$_[1][2]}[0] + @{$_[0][0]}[3]*@{$_[1][3]}[0] , @{$_[0][0]}[0]*@{$_[1][0]}[1] + @{$_[0][0]}[1]*@{$_[1][1]}[1] + @{$_[0][0]}[2]*@{$_[1][2]}[1] + @{$_[0][0]}[3]*@{$_[1][3]}[1] , @{$_[0][0]}[0]*@{$_[1][0]}[2] + @{$_[0][0]}[1]*@{$_[1][1]}[2] + @{$_[0][0]}[2]*@{$_[1][2]}[2] + @{$_[0][0]}[3]*@{$_[1][3]}[2] , @{$_[0][0]}[0]*@{$_[1][0]}[3] + @{$_[0][0]}[1]*@{$_[1][1]}[3] + @{$_[0][0]}[2]*@{$_[1][2]}[3] + @{$_[0][0]}[3]*@{$_[1][3]}[3] ],	#a11b11+a12b21+a13b31+a14b41,a11b12+a12b22+a13b32+a14b42,a11b13+a12b23+a13b33+a14b43,a11b14+a12b24+a13b34+a14b44
		[ @{$_[0][1]}[0]*@{$_[1][0]}[0] + @{$_[0][1]}[1]*@{$_[1][1]}[0] + @{$_[0][1]}[2]*@{$_[1][2]}[0] + @{$_[0][1]}[3]*@{$_[1][3]}[0] , @{$_[0][1]}[0]*@{$_[1][0]}[1] + @{$_[0][1]}[1]*@{$_[1][1]}[1] + @{$_[0][1]}[2]*@{$_[1][2]}[1] + @{$_[0][1]}[3]*@{$_[1][3]}[1] , @{$_[0][1]}[0]*@{$_[1][0]}[2] + @{$_[0][1]}[1]*@{$_[1][1]}[2] + @{$_[0][1]}[2]*@{$_[1][2]}[2] + @{$_[0][1]}[3]*@{$_[1][3]}[2] , @{$_[0][1]}[0]*@{$_[1][0]}[3] + @{$_[0][1]}[1]*@{$_[1][1]}[3] + @{$_[0][1]}[2]*@{$_[1][2]}[3] + @{$_[0][1]}[3]*@{$_[1][3]}[3] ],	#a21b11+a22b21+a23b31+a24b41,a21b12+a22b22+a23b32+a24b42,a21b13+a22b23+a23b33+a24b43,a21b14+a22b24+a23b34+a24b44
		[ @{$_[0][2]}[0]*@{$_[1][0]}[0] + @{$_[0][2]}[1]*@{$_[1][1]}[0] + @{$_[0][2]}[2]*@{$_[1][2]}[0] + @{$_[0][2]}[3]*@{$_[1][3]}[0] , @{$_[0][2]}[0]*@{$_[1][0]}[1] + @{$_[0][2]}[1]*@{$_[1][1]}[1] + @{$_[0][2]}[2]*@{$_[1][2]}[1] + @{$_[0][2]}[3]*@{$_[1][3]}[1] , @{$_[0][2]}[0]*@{$_[1][0]}[2] + @{$_[0][2]}[1]*@{$_[1][1]}[2] + @{$_[0][2]}[2]*@{$_[1][2]}[2] + @{$_[0][2]}[3]*@{$_[1][3]}[2] , @{$_[0][2]}[0]*@{$_[1][0]}[3] + @{$_[0][2]}[1]*@{$_[1][1]}[3] + @{$_[0][2]}[2]*@{$_[1][2]}[3] + @{$_[0][2]}[3]*@{$_[1][3]}[3] ],	#a31b11+a32b21+a33b31+a34b41,a31b12+a32b22+a33b32+a34b42,a31b13+a32b23+a33b33+a34b43,a31b14+a32b24+a33b34+a34b44
		[ @{$_[0][3]}[0]*@{$_[1][0]}[0] + @{$_[0][3]}[1]*@{$_[1][1]}[0] + @{$_[0][3]}[2]*@{$_[1][2]}[0] + @{$_[0][3]}[3]*@{$_[1][3]}[0] , @{$_[0][3]}[0]*@{$_[1][0]}[1] + @{$_[0][3]}[1]*@{$_[1][1]}[1] + @{$_[0][3]}[2]*@{$_[1][2]}[1] + @{$_[0][3]}[3]*@{$_[1][3]}[1] , @{$_[0][3]}[0]*@{$_[1][0]}[2] + @{$_[0][3]}[1]*@{$_[1][1]}[2] + @{$_[0][3]}[2]*@{$_[1][2]}[2] + @{$_[0][3]}[3]*@{$_[1][3]}[2] , @{$_[0][3]}[0]*@{$_[1][0]}[3] + @{$_[0][3]}[1]*@{$_[1][1]}[3] + @{$_[0][3]}[2]*@{$_[1][2]}[3] + @{$_[0][3]}[3]*@{$_[1][3]}[3] ]	#a41b11+a42b21+a43b31+a44b41,a41b12+a42b22+a43b32+a44b42,a41b13+a42b23+a43b33+a44b43,a41b14+a42b24+a43b34+a44b44
	);

	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#4X4 x 1x3 MATRIX MULTIPLY (move vert by 4x4 matrix)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @vertPos = vec_mtxMult(\@matrix,\@vertPos);
#arg0 = transform matrix.  arg1 = vertPos to multiply to that then sends the results to the cvar.
sub vec_mtxMult{
	my @pos = (
		@{$_[0][0]}[0]*@{$_[1]}[0] + @{$_[0][0]}[1]*@{$_[1]}[1] + @{$_[0][0]}[2]*@{$_[1]}[2] + @{$_[0][0]}[3],	#a1*x_old + a2*y_old + a3*z_old + a4
		@{$_[0][1]}[0]*@{$_[1]}[0] + @{$_[0][1]}[1]*@{$_[1]}[1] + @{$_[0][1]}[2]*@{$_[1]}[2] + @{$_[0][1]}[3],	#b1*x_old + b2*y_old + b3*z_old + b4
		@{$_[0][2]}[0]*@{$_[1]}[0] + @{$_[0][2]}[1]*@{$_[1]}[1] + @{$_[0][2]}[2]*@{$_[1]}[2] + @{$_[0][2]}[3]	#c1*x_old + c2*y_old + c3*z_old + c4
	);

	#dividing @pos by (matrix's 4,4) to correct "projective space"
	$pos[0] = $pos[0] / @{$_[0][3]}[3];
	$pos[1] = $pos[1] / @{$_[0][3]}[3];
	$pos[2] = $pos[2] / @{$_[0][3]}[3];

	return @pos;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CONVERT 3X3 MATRIX TO 4X4 MATRIX
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#my @4x4Matrix = convert3x3M_4x4M(\@3x3Matrix);
sub convert3x3M_4x4M{
	my ($m) = $_[0];
	my @matrix = (
		[$$m[0][0],$$m[0][1],$$m[0][2],0],
		[$$m[1][0],$$m[1][1],$$m[1][2],0],
		[$$m[2][0],$$m[2][1],$$m[2][2],0],
		[0,0,0,1]
	);

	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET ITEM XFRM MATRIX (of the item and all it's parents and pivots)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @itemXfrmMatrix = getItemXfrmMatrix($itemID);
#if you multiply the verts by it's matrix, it gives their world positions.
sub getItemXfrmMatrix{
	my ($id) = $_[0];

	my @matrix = (
		[1,0,0,0],
		[0,1,0,0],
		[0,0,1,0],
		[0,0,0,1]
	);

	while ($id ne ""){
		my @transformIDs = lxq("query sceneservice item.xfrmItems ? {$id}");
		my @pivotTransformIDs;
		my @pivotRotationIDs;

		#find any pivot move or pivot rotate transforms
		foreach my $transID (@transformIDs){
			my $name = lxq("query sceneservice item.name ? $transID");
			$name =~ s/\s\([0-9]+\)$//;
			if ($name eq "Pivot Position"){
				push(@pivotTransformIDs,$transID);
			}elsif ($name eq "Pivot Rotation"){
				push(@pivotRotationIDs,$transID);
			}
		}

		#go through transforms
		foreach my $transID (@transformIDs){
			my $name = lxq("query sceneservice item.name ? $transID");
			my $type = lxq("query sceneservice item.type ? $transID");
			my $channelCount = lxq("query sceneservice channel.n ?");

			#rotation
			if ($type eq "rotation"){
				my $rotX = lxq("item.channel rot.X {?} set {$transID}");
				my $rotY = lxq("item.channel rot.Y {?} set {$transID}");
				my $rotZ = lxq("item.channel rot.Z {?} set {$transID}");
				my $rotOrder = uc(lxq("item.channel order {?} set {$transID}")) . "s";
				my @rotMatrix = Eul_ToMatrix($rotX,$rotY,$rotZ,$rotOrder,"degrees");
				@rotMatrix = convert3x3M_4x4M(\@rotMatrix);
				@matrix = mtxMult(\@rotMatrix,\@matrix);
			}

			#translation
			elsif ($type eq "translation"){
				my $posX = lxq("item.channel pos.X {?} set {$transID}");
				my $posY = lxq("item.channel pos.Y {?} set {$transID}");
				my $posZ = lxq("item.channel pos.Z {?} set {$transID}");
				my @posMatrix = (
					[1,0,0,$posX],
					[0,1,0,$posY],
					[0,0,1,$posZ],
					[0,0,0,1]
				);
				@matrix = mtxMult(\@posMatrix,\@matrix);
			}

			#scale
			elsif ($type eq "scale"){
				my $sclX = lxq("item.channel scl.X {?} set {$transID}");
				my $sclY = lxq("item.channel scl.Y {?} set {$transID}");
				my $sclZ = lxq("item.channel scl.Z {?} set {$transID}");
				my @sclMatrix = (
					[$sclX,0,0,0],
					[0,$sclY,0,0],
					[0,0,$sclZ,0],
					[0,0,0,1]
				);
				@matrix = mtxMult(\@sclMatrix,\@matrix);
			}

			#transform
			elsif ($type eq "transform"){
				#transform : piv pos
				if ($name =~ /pivot position inverse/i){
					my $posX = lxq("item.channel pos.X {?} set {$pivotTransformIDs[0]}");
					my $posY = lxq("item.channel pos.Y {?} set {$pivotTransformIDs[0]}");
					my $posZ = lxq("item.channel pos.Z {?} set {$pivotTransformIDs[0]}");
					my @posMatrix = (
						[1,0,0,$posX],
						[0,1,0,$posY],
						[0,0,1,$posZ],
						[0,0,0,1]
					);
					@posMatrix = inverseMatrix(\@posMatrix);
					@matrix = mtxMult(\@posMatrix,\@matrix);
				}

				#transform : piv rot
				elsif ($name =~ /pivot rotation inverse/i){
					my $rotX = lxq("item.channel rot.X {?} set {$pivotRotationIDs[0]}");
					my $rotY = lxq("item.channel rot.Y {?} set {$pivotRotationIDs[0]}");
					my $rotZ = lxq("item.channel rot.Z {?} set {$pivotRotationIDs[0]}");
					my $rotOrder = uc(lxq("item.channel order {?} set {$pivotRotationIDs[0]}")) . "s";
					my @rotMatrix = Eul_ToMatrix($rotX,$rotY,$rotZ,$rotOrder,"degrees");
					@rotMatrix = convert3x3M_4x4M(\@rotMatrix);
					@rotMatrix = transposeRotMatrix(\@rotMatrix);
					@matrix = mtxMult(\@rotMatrix,\@matrix);
				}

				else{
					lxout("type is a transform, but not a PIVPOSINV or PIVROTINV! : $type");
				}
			}

			#other?!
			else{
				lxout("type is neither rotation or translation! : $type");
			}
		}
		$id = lxq("query sceneservice item.parent ? $id");
	}
	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CONVERT EULER ANGLES TO (3 X 3) MATRIX (in any rotation order)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @3x3Matrix = Eul_ToMatrix($xRot,$yRot,$zRot,"ZXYs",degrees|radians);
# - the angles must be radians unless the fifth argument is "degrees" in which case the sub will convert it to radians for you.
# - must insert the X,Y,Z rotation values in the listed order.  the script will rearrange them internally.
# - as for the rotation order cvar, the last character is "s" or "r".  Here's what they mean:
#	"s" : "static axes"		: use this as default
#	"r" : "rotating axes"	: for body rotation axes?
# - resulting matrix must be inversed or transposed for it to be correct in modo.
sub Eul_ToMatrix{
	my $pi = 3.14159265358979323;
	my $FLT_EPSILON = 0.00000000000000000001;
	my $EulFrmS = 0;
	my $EulFrmR = 1;
	my $EulRepNo = 0;
	my $EulRepYes = 1;
	my $EulParEven = 0;
	my $EulParOdd = 1;
	my @EulSafe = (0,1,2,0);
	my @EulNext = (1,2,0,1);
	my @ea = @_;
	my @m = ([0,0,0],[0,0,0],[0,0,0]);

	#convert degrees to radians if user specified
	if ($_[4] eq "degrees"){
		$ea[0] *= $pi/180;
		$ea[1] *= $pi/180;
		$ea[2] *= $pi/180;
	}

	#reorder rotation value args to match same order as rotation order.
	my $rotOrderCopy = $ea[3];
	$rotOrderCopy =~ s/X/$ea[0],/g;
	$rotOrderCopy =~ s/Y/$ea[1],/g;
	$rotOrderCopy =~ s/Z/$ea[2],/g;
	my @eaCopy = split(/,/, $rotOrderCopy);
	$ea[0] = $eaCopy[0];
	$ea[1] = $eaCopy[1];
	$ea[2] = $eaCopy[2];

	my %rotOrderSetup = (
		"XYZs" , 0,		"XYXs" , 2,		"XZYs" , 4,		"XZXs" , 6,
		"YZXs" , 8,		"YZYs" , 10,	"YXZs" , 12,	"YXYs" , 14,
		"ZXYs" , 16,	"ZXZs" , 18,	"ZYXs" , 20,	"ZYZs" , 22,
		"ZYXr" , 1,		"XYXr" , 3,		"YZXr" , 5,		"XZXr" , 7,
		"XZYr" , 9,		"YZYr" , 11,	"ZXYr" , 13,	"YXYr" , 15,
		"YXZr" , 17,	"ZXZr" , 19,	"XYZr" , 21,	"ZYZr" , 23
	);
	$ea[3] = $rotOrderSetup{$ea[3]};

	#initial code
	$o=$ea[3]&31;
	$f=$o&1;
	$o>>=1;
	$s=$o&1;
	$o>>=1;
	$n=$o&1;
	$o>>=1;
	$i=$EulSafe[$o&3];
	$j=$EulNext[$i+$n];
	$k=$EulNext[$i+1-$n];
	$h=$s?$k:$i;

	if ($f == $EulFrmR)		{	$t = $ea[0]; $ea[0] = $ea[2]; $ea[2] = $t;				}
	if ($n == $EulParOdd)	{	$ea[0] = -$ea[0]; $ea[1] = -$ea[1]; $ea[2] = -$ea[2];	}
	$ti = $ea[0];
	$tj = $ea[1];
	$th = $ea[2];

	$ci = cos($ti); $cj = cos($tj); $ch = cos($th);
	$si = sin($ti); $sj = sin($tj); $sh = sin($th);
	$cc = $ci*$ch; $cs = $ci*$sh; $sc = $si*$ch; $ss = $si*$sh;

	if ($s == $EulRepYes) {
		$m[$i][$i] = $cj;		$m[$i][$j] =  $sj*$si;			$m[$i][$k] =  $sj*$ci;
		$m[$j][$i] = $sj*$sh;	$m[$j][$j] = -$cj*$ss+$cc;		$m[$j][$k] = -$cj*$cs-$sc;
		$m[$k][$i] = -$sj*$ch;	$m[$k][$j] =  $cj*$sc+$cs;		$m[$k][$k] =  $cj*$cc-$ss;
	}else{
		$m[$i][$i] = $cj*$ch;	$m[$i][$j] = $sj*$sc-$cs;		$m[$i][$k] = $sj*$cc+$ss;
		$m[$j][$i] = $cj*$sh;	$m[$j][$j] = $sj*$ss+$cc;		$m[$j][$k] = $sj*$cs-$sc;
		$m[$k][$i] = -$sj;		$m[$k][$j] = $cj*$si;			$m[$k][$k] = $cj*$ci;
    }

    return @m;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PRINT MATRIX (4x4)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : printMatrix(\@matrix);
sub printMatrix{
	lxout("==========");
	for (my $i=0; $i<4; $i++){
		for (my $u=0; $u<4; $u++){
			lxout("[$i][$u] = @{$_[0][$i]}[$u]");
		}
		lxout("\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY ITEM REFERENCE MODE MATRIX (4x4)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @itemRefMatrix = queryItemRefMatrix();
#if you multiply a vert by this matrix, you'll get the vert pos you see in screenspace
sub queryItemRefMatrix{
	my $itemRef = lxq("item.refSystem ?");
	if ($itemRef eq ""){
		my @matrix = (
			[1,0,0,0],
			[0,1,0,0],
			[0,0,1,0],
			[0,0,0,1]
		);
		return @matrix;
	}else{
		my @itemXfrmMatrix = getItemXfrmMatrix($itemRef);
		@itemXfrmMatrix = inverseMatrix(\@itemXfrmMatrix);

		return @itemXfrmMatrix;
	}
}

