{$A+,B-,D-,E+,F-,G-,I+,L-,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y-}
{$M 16384,0,655360}
uses crt;
const
	pi = 3.1459;
	pi_2 = pi/2;
	pi10000 = 31459; {чтобы в цикле не вычислять выражение 10000*пи}
	rh = 0.529; {радиус первой орбиты атома водорода}
	n = 50; {максимальное количество частиц}
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
var
	{n0 = 1; r0 = 0; q0 = 2;
	n1 = 4; r1 = 3; q1 = -2;
	n2 = 1; r2 = 4.5; q2 = +2;
	B=10; aa=1; bb=1; A=1; {}
	
	q0, n1, q1, n2, q2: integer;
	max_iter : longint;
	h, debug, r1, r2, B, aa, bb, A, 
	Vr0, Vl0, Ror, Rol,
	Vr1, Vl1, Ror1, Rol1,
	Vr2, Vl2, Ror2, Rol2:double;

	arr: TArr;
	R  : TRij;
	{процедура считывает из файла константы}
	procedure read_constant(s:string);
	var
		f:text;
	begin
		assign(f,s); reset(f);
		readln(f,max_iter, debug);
		readln(f,q0);
		readln(f,n1,r1,q1);
		readln(f,n2,r2,q2);
		{readln(f,A,B,aa,bb);{}
		readln(f,Vr0,Vl0,Ror,Rol);
		readln(f,Vr1,Vl1,Ror1,Rol1);
		readln(f,Vr2,Vl2,Ror2,Rol2);
		close(f);
	end;
	{возведение числа х в степень n}
	function power(x: double; n:integer) : double;
	var 
		i,m:integer;
		rez:double;
	begin
		if n=0 then power:=1 {нулевая степень числа всегда равна 1}
		else begin
			m := abs(n); 
			rez:=1;
			for i:=1 to m do rez := rez * x;
			if n>0 then power := rez
			else        power := 1/rez;
		end;
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
	
	{сила с которой i1-я частица действует на i2-ю}
	function Vr(i1,i2: word) : double;
	begin
		if (i1 < i2) then
		begin
			if(i1=0) then
			begin
				if(arr[i2,4]=q1)then
					Vr := Vr0*(power(R[i1,i2]/Ror, -12) - power(R[i1,i2]/Ror, -6)){}
				else
					Vr := Vl2*power(R[i1,i2]/Rol1, -12) {}
			end
			else if (arr[i1,4]=arr[i2,4]) then 
			begin
				if(arr[i2,4]=q1)then
					Vr := Vl0*power(R[i1,i2]/Rol, -12) {}
				else
					Vr := Vl1*power(R[i1,i2]/Rol1, -12) {}
				{Vr :=arr[i1,4]*arr[i2,4]/R[i1,i2]{}
			end
			else 
				Vr := Vr2*(power(R[i1,i2]/Ror2, -12) - power(R[i1,i2]/Ror2, -6)){}
				{Vr :=arr[i1,4]*arr[i2,4]/R[i1,i2] + B/power(R[i1,i2],9){}
			{Vr := arr[i1,4]*arr[i2,4]/R[i1,i2] + B*power(R[i1,i2],-12);{}
		end
		else
			Vr :=0;
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
		h:=0.4;
		check := 0;
		if (debug=1) then 
		begin 
			assign(f, 'out.txt'); rewrite(f); 
		end;
		
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
				if (debug=1) then writeln(f,curr_E:0:10);
				inc(check);
				if(check=9)or(check=90)or(check=200)or(check=500)or(check=1000)
					then h:=h/2;
			end;
		end;
		
		if (debug=1) then
		begin
			writeln(f,max_iter,' ',check, ' ',(check/max_iter*100):0:8,'%');
			close(f);
		end;
	end;
	{процедура печати координат частиц в специальном формате Maple}
	procedure maple_out;
	var
		i, j:word;
		fm:text;
	begin
		assign(fm,'maple.txt'); rewrite(fm);
		writeln(fm, 'restart: with(plots,Interactive,pointplot3d):'
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

		for i :=0 to n1+n2-1 do 
		begin
			write(fm, '#');
			for j:=0 to n1+n2 do
				write(fm, R[i,j]:8:5,' |');
			writeln(fm);
		end;
		writeln(fm,'#',Vr0:0:3,' ',Vl0:0:3,' ',Ror:0:3,' ',Rol:0:3);
		
		close(fm);
	end;
begin
	randomize;
	
	{= Считываем исходные данные из файла =}
	read_constant('input.txt');
	
	{= Случайный Разброс частиц =}
	random_array;
	
	{= Релаксация системы =}
	relax;{}
	
	{= Вывод координат частиц =}
	maple_out;
	
end.