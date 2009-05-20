{$A+,B-,D-,E+,F-,G-,I+,L-,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y-}
{$M 16384,0,655360}
uses crt;
const
	pi = 3.1459;
	pi_2 = pi/2;
	pi10000 = 31459; {чтобы в цикле не вычислять выражение 10000*пи}
	rh = 0.529; {радиус первой орбиты атома водорода}
	n = 20; {максимальное количество частиц}
	poly1 = #13#10'Shape {geometry IndexedLineSet { colorPerVertex FALSE'+
			#13#10'coord Coordinate {point [';
	poly2 = ']}'#13#10'color Color {color [';
	{Vr0 = 8;
	Vl0 = 1;
	Ror = 1;
	Rol = Ror;{}
type
	TArr = array[0..n,1..4] of double; {массив из частиц
		первый индекс это номер частицы. второй индекс это координата
		частицы}
	
	TRij = array[0..n,0..n] of double; {массив хранящий расстояния
		между частицами. например R[2,8] - будет равно расстоянию между 
		2 и 8 частицами}
	
	TPoly = array[0..100,1..2]of word;
var
	{n0 = 1; r0 = 0; q0 = 2;
	n1 = 4; r1 = 3; q1 = -2;
	n2 = 1; r2 = 4.5; q2 = +2;{}
	
	q0, n1, q1, n2, q2, i, j: integer;
	max_iter : longint;
	h, debug, r1, r2:double; 
	ftype:array [0..6] of byte;
	cnst:array [1..5,1..4]of double; {константы}
	pr:array[1..100,1..2]of word;
	arr: TArr;
	R  : TRij;
	color : array[0..2]of string;
	rview : array[0..2]of double;
	{процедура считывает из файла константы}
	procedure read_constant(s:string);
	var
		f:text;
		ch:char;
	begin
{
0 1 3
0 2 4
1 1 4
2 2 4
1 2 3

1 Const1*q1*q2/R +Const2*exp(R/Const3)
2 Const1*q1*q2/rij + Const2*(R/Const3)^x (x=-7..-9);
3 Const1*(R/Const2)^-12) - (R/Const2)^-6)
4 Const1*(R/Const2)^-12}
		assign(f,s); reset(f);
		readln(f,max_iter, debug);
		readln(f,q0);
		readln(f,n1,r1,q1);
		readln(f,n2,r2,q2);
		while (not EOLN(f)) do begin
			read(f, ch);
			
			color[0] := concat(color[0],ch);
		end; readln(f);
		while (not EOLN(f)) do begin
			read(f, ch);
			
			color[1] := concat(color[1],ch);
		end; readln(f);
		while (not EOLN(f)) do begin
			read(f, ch);
			
			color[2] := concat(color[2],ch);
		end; readln(f);
		readln(f,rview[0],rview[1],rview[2]);
		readln(f,ftype[1],cnst[1,1],cnst[1,2],cnst[1,3]);
		readln(f,ftype[2],cnst[2,1],cnst[2,2],cnst[3,3]);
		readln(f,ftype[3],cnst[3,1],cnst[3,2],cnst[3,3]);
		readln(f,ftype[4],cnst[4,1],cnst[4,2],cnst[4,3]);
		readln(f,ftype[5],cnst[5,1],cnst[5,2],cnst[5,3]);
		ftype[0]:=0;
		close(f);
	end;
	{возведение числа х в степень n}
	function power(x: double; n:integer) : double;
	var 
		i,m:integer;
		rez:double;
	begin
		(*if n=0 then power:=1 {нулевая степень числа всегда равна 1}
		else begin
			m := abs(n); 
			rez:=1;
			for i:=1 to m do rez := rez * x;
			if n>0 then power := rez
			else        power := 1/rez;
		end;*)
		power:=exp(n*ln(x));
	end;
	
	function ArcSin(x:double):double;
	begin
		ArcSin:=Arctan(x/Sqrt(1-x*x));
	end;

	{функция вычисляет расстояние между частицами}
	function Rij(i1,i2:word) : double;
	var 
		dx,dy,dz:double;
	begin
		if(i1>i2) then Rij := 0
		else begin
			dx := arr[i1,1]-arr[i2,1];
			dy := arr[i1,2]-arr[i2,2];
			dz := arr[i1,3]-arr[i2,3];
			R[i1,i2] := sqrt(dx*dx+dy*dy+dz*dz); {}
			Rij := R[i1,i2];
		end;
	end;
	
	{первоначальный разброс частиц}
	procedure random_array;
	var 
		i, j : word;
		phi, tetta : double;
	begin
		arr[0,1] := 0; arr[0,2] := 0; arr[0,3] := 0; 
		arr[0,4] := q0; 
		for i:=1 to n1 do 
		begin
			phi := random(pi10000+pi10000)/10000;
			tetta := ArcSin(2 * random(10000)/10000 - 1) + pi_2;{}
			arr[i,1] := r1*sin(tetta)*cos(phi); {x}
			arr[i,2] := r1*sin(tetta)*sin(phi); {y}
			arr[i,3] := r1*cos(tetta);          {z}
			arr[i,4] := q1;
		end;
		for i:=n1+1 to n1+n2 do 
		begin
			phi := random(pi10000+pi10000)/10000;
			tetta := ArcSin(2 * random(10000)/10000 - 1) + pi_2;{}
			arr[i,1] := r2*sin(tetta)*cos(phi); {x}
			arr[i,2] := r2*sin(tetta)*sin(phi); {y}
			arr[i,3] := r2*cos(tetta);          {z}
			arr[i,4] := q2;
		end;
		for i :=0 to n1+n2 do
			for j:=i+1 to n1+n2 do
				Rij(i,j);
	end;
	
	{сила с которой i-я частица действует на j-ю}
	function Vr(i,j: word) : double;
	var
		ft:byte;
	begin
		if (i < j) then
		begin
			if(i=0) then
			begin
				if(arr[j,4]=q1)then
					ft:=1 {Vr := Vr0*(power(R[i,j]/Ror, -12) - power(R[i,j]/Ror, -6)){}
				else
					ft:=2; {Vr := Vl2*power(R[i,j]/Rol1, -12) {}
			end
			else if (arr[i,4]=arr[j,4]) then 
			begin
				if(arr[j,4]=q1)then
					ft:=3{Vr := Vl0*power(R[i,j]/Rol, -12) {}
				else
					ft:=4;{Vr := Vl1*power(R[i,j]/Rol1, -12) {}
			end
			else 
				ft:=5;{Vr := Vr2*(power(R[i,j]/Ror2, -12) - power(R[i,j]/Ror2, -6)){}
				{Vr :=arr[i,4]*arr[j,4]/R[i,j] + B/power(R[i,j],9){}
			{Vr := arr[i,4]*arr[j,4]/R[i,j] + B*power(R[i,j],-12);{}
		end
		else
			ft:=0;{Vr :=0;{}
		
		case ftype[ft] of
			1: Vr := cnst[ft,1] * arr[i,4] * arr[j,4] / R[i,j] + 
					cnst[ft,2] * exp(R[i,j] / cnst[ft,3]);
			2: Vr := cnst[ft,1]*arr[i,4]*arr[j,4]/R[i,j] + 
					cnst[ft,2]*power(R[i,j]/cnst[ft,3], -8);
			3: Vr := cnst[ft,1]*(power(R[i,j]/cnst[ft,2],-12) -
					power(R[i,j]/cnst[ft,2], -6));
			4: Vr := cnst[ft,1]*power(R[i,j]/cnst[ft,2],-12);
			5: Vr := cnst[ft,1]*arr[i,4]*arr[j,4]/R[i,j] + cnst[ft,2]*power(R[i,j]/cnst[ft,3],-12);
			else Vr := 0;
		end;{}
	end;
	
	{энергия системы}
	function E : double;
	var
		i,j:word;
		rez: double;
	begin
		rez :=0;
		for i :=0 to n1+n2 do
		{обратите внимание на пределы цикла по j}
			for j:=i+1 to n1+n2 do
				rez := rez + Vr(i,j);
		E := rez;
	end;
	
	{функция обновляет расстояния для к-ой частицы}
	procedure pereschet_R(k:word);
	var
		i:word;
	begin
		for i := 0 to k-1 do Rij(i,k);
		for i := k+1 to n1+n2 do Rij(k,i);
	end;
	{процедура релаксации}
	procedure relax;
	var
		dx,dy,dz, curr_E, prev_E,cR :double;
		k :word;
		i, j, check:longint;
		f:text;
	begin
		h:=0.3;
		check := 0;
		{if (debug=1) then 
		begin 
			assign(f, 'out.txt'); rewrite(f); 
		end;{}
		
		prev_E := E; {предыдущее значении энергии. Обратите внимание E - 
		это не переменная, это процедура}
		for i:=1 to max_iter do
		begin
			k := random(n1+n2) + 1;
			{Выражение (random(10000) - 50000) / 5000000 будет возвращать
			случайные значения в интервале (0.01)}
			dx := (random - 0.5) * h; {случайное смещение }
			dy := (random - 0.5) * h; 
			dz := (random - 0.5) * h; 
			arr[k, 1] := arr[k, 1] + dx;
			arr[k, 2] := arr[k, 2] + dy;
			arr[k, 3] := arr[k, 3] + dz;
			pereschet_R(k);
			curr_E := E; 
			j:=-1;

			{так как мы сдвинули к-ую частицу то необходимо обновить
			таблицу расстояний }
			
			{если значение энергии увеличилось, то такое
			смещение частицы отвергается (частица возвращается в 
			исходное состояние)}
			if((j<>-1)or(curr_E>prev_E)) then
			begin
				arr[k, 1] := arr[k, 1] - dx;
				arr[k, 2] := arr[k, 2] - dy;
				arr[k, 3] := arr[k, 3] - dz;{}
				pereschet_R(k);
			end
			else begin
				prev_E := curr_E;
				{if (debug=1) then writeln(f,curr_E:0:10);{}
				inc(check);
				if(check=9)or(check=90)or(check=200)or(check=500)or(check=1000)
					then h:=h/2;
			end;
		end;
		
		{if (debug=1) then
		begin
			writeln(f,max_iter,' ',check, ' ',(check/max_iter*100):0:8,'%');
			close(f);
		end;{}
	end;
	{процедура печати координат частиц в специальном формате Maple}
	procedure maple_out;
	var
		i, j:word;
		fm:text;
	begin
		assign(fm,'maple.txt'); rewrite(fm);
		writeln(fm, 'restart: with(plots,pointplot3d):'
			,#13#10'pointplot3d({');
		for i :=0 to n1+n2-1 do
		begin
			writeln(fm, '[', arr[i,1]:0:10,', ',
				arr[i,2]:0:10,', ',
				arr[i,3]:0:10,'], #',R[0,i]:6:2,arr[i,4]:4:0);
		end;
		writeln(fm,'[', arr[n1+n2,1]:0:10,', ',
			arr[n1+n2,2]:0:10,', ',
			arr[n1+n2,3]:0:10,']  #',R[0,n1+n2]:6:2,arr[n1+n2,4]:4:0,
			#13#10'},axes=normal,symbol=circle,symbolsize=14);');

		{for i :=0 to n1+n2-1 do 
		begin
			write(fm, '#');
			for j:=0 to n1+n2 do
				write(fm, R[i,j]:8:5,' |');
			writeln(fm);
		end;{}

		close(fm);
	end;

	function poly(k:integer):string;
	var
		i,j,a,b,l:byte;
		min,t:word;
		s:string;
	begin
		s:='';
		case k of
			0,1: s:='';
			2: s:='0 1 ';
			3: s:='0 1 2 ';
			4: s:='3 2 0 1 2 0 3 1 ';
			else begin
				s:='ddd';
				if(k=n1)then begin a:=1; b:=n1; end
				else begin a:=1+n1; b:=n1+n2; end;
				l:=1;
				for i:=a to b-1 do
					for j:=i+1 to b do
					begin
						pr[l,1]:=round(R[i,j]*1000);
						pr[l,2]:=i+(j shl 8);
						inc(l);
					end;
				dec(l);
				{for i:=1 to l do write(chr((pr[i,2] and 255)+48)+' '+chr((pr[i,2] shr 8)+48)+' : ');
				writeln(#13#10,n1,n2,k,a,b);
				readln;{}
				for i:=1 to l-1 do
				begin
					min:=i;
					for j:=i+1 to l do
					if(pr[j,1]<pr[min,1]) then
					begin
						t:=pr[j,1]; pr[j,1]:=pr[min,1]; pr[min,1]:=t;
						t:=pr[j,2]; pr[j,2]:=pr[min,2]; pr[min,2]:=t;
						min:=j;
					end;
				end;
				case k of 
					4:t:=5;
					5:t:=7;
					else t:=k+k;
				end;
				pr[100,1]:=t;
				{for i:=1 to t do
					s:=s+chr((pr[i,2] and 255)+48-a)+' '+chr((pr[i,2] shr 8)+48-a)+' ';}
			end;
		end;
		poly:=s;
	end;
	procedure _3dmaxout(filename:string);
	var
		i,cl,i1,i2:word;
		fm:text;
		p:string;
	begin
		assign(fm, filename); rewrite(fm);
		writeln(fm, '#VRML V2.0 utf8');
		for i :=0 to n1+n2 do
		begin
			if(i>0) and (i<=n1) then cl := 1
			else if(i>n1) then cl :=2
			else cl:=0;
			writeln(fm, 'DEF Sphere',i,' Transform {'#13#10,
			'translation ',arr[i,1]:14:10,' ',arr[i,2]:14:10,' ',arr[i,3]:14:10,#13#10,
			'children [  Shape {  appearance Appearance {   material ',
			'Material { diffuseColor ',color[cl],' } } geometry ',
			'Sphere { radius ',rview[cl]:7:4 ,' } }  ] }');
		end;
		
		p:=poly(n1);
		if((p<>'') and (p<>'ddd')) then
		begin
			writeln(fm, poly1);
			for i:=1 to n1 do
				writeln(fm, arr[i,1]:14:10,' ',arr[i,2]:14:10,' ',arr[i,3]:14:10,',');
			writeln(fm, poly2,color[1],
			']}'#13#10,'coordIndex [',p,' -1]}}');
		end else if(p='ddd') then
			for i:=1 to pr[100,1] do
			begin
				i1:=pr[i,2] and 255;
				i2:=pr[i,2] shr 8;
				writeln(fm, poly1, arr[i1,1]:14:10,' ',arr[i1,2]:14:10,' ',
				arr[i1,3]:14:10,',',arr[i2,1]:14:10,' ',arr[i2,2]:14:10,' ',
				arr[i2,3]:14:10,poly2,color[1],']}'#13#10,
				'coordIndex [0 1 -1]}}');
			end;
		
		
		if(n2>1)then begin
		p:=poly(n2);
		if((p<>'') and (p<>'ddd')) then
		begin
			writeln(fm, poly1);
			for i:=1 to n2 do
				writeln(fm, arr[n1+i,1]:14:10,' ',arr[n1+i,2]:14:10,' ',arr[n1+i,3]:14:10,',');
			writeln(fm, poly2,color[2],
			']}'#13#10,'coordIndex [',p,' -1]}}');
		end else if(p='ddd') then
			for i:=1 to pr[100,1] do
			begin
				i1:=pr[i,2] and 255;
				i2:=pr[i,2] shr 8;
				writeln(fm, poly1, arr[i1,1]:14:10,' ',arr[i1,2]:14:10,' ',
				arr[i1,3]:14:10,',',arr[i2,1]:14:10,' ',arr[i2,2]:14:10,' ',
				arr[i2,3]:14:10,poly2,color[2],']}'#13#10,
				'coordIndex [0 1 -1]}}');
			end;

		end;
		close(fm);
	end;
begin
	randomize;
	{= Считываем исходные данные из файла =}
	read_constant('input.txt');
	{= Случайный Разброс частиц =}
	writeln('Begin generation...');
	{$I-}
	{ Get directory name from command line }
	MkDir('WRL');
	if IOResult <> 0 then
		writeln('Cannot create directory \WRL')
	  else
		writeln('Directory \WRL created ');{}
	{$I+}
	for i:=4 to 8 do
	begin
		j:=2;
		if(i>5) then j:=3;
		for j:=0 to j do
		begin
			n1:=i; n2:=j;
			write('wrl\_'+chr(i+48)+'_'+chr(j+48)+'.WRL ...');
			random_array;
			{= Релаксация системы =}
			relax;{}
			{= Вывод координат частиц =}
			_3dmaxout('wrl\_'+chr(i+48)+'_'+chr(j+48)+'.WRL');
			{}
			writeln(' - [ok] ');
		end;
	end;
end.