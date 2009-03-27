{$A+,B-,D-,E+,F-,G-,I+,L-,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y-}
{$M 16384,0,655360}
uses crt;
const
	n0 = 1; r0 = 0; q0 = 2;
	n1 = 8; r1 = 3; q1 = -2;
	n2 = 0; r2 = 4.5; q2 = +2;
	pi = 3.1459;
	pi_2 = pi/2;
	pi10000 = 31459; {чтобы в цикле не вычислять выражение 10000*пи}
	rh = 0.529; {радиус первой орбиты атома водорода}
	B=42;
	aa=2;
	bb=4;
	A=100;
type
	TArr = array[0..n1+n2,1..4] of double; {массив из частиц}
	TRij = array[0..n1+n2,0..n1+n2] of double; {массив хранящий расстояния
		между частицами. например R[2,8] - будет равно расстоянию между 
		2 и 8 частицами}
var
	f  : text;
	arr: TArr;
	R  : TRij;
	{возведение числа х в степень n}
	function power(x: double; n:word) : double;
	var 
		i:word;
		rez:double;
	begin
		rez:=1;
		for i:=1 to n do rez := rez * x;
		power:=rez;
	end;
	
	{расстояние между частицами}
	function ArcSin( x:double):double;
	begin
		ArcSin:=Arctan(x/Sqrt(1-x*x));
	end;
	function Rij(i1,i2:word) : double;
	var 
		dx,dy,dz:double;
	begin
		dx := arr[i1,1]-arr[i2,1];
		dy := arr[i1,2]-arr[i2,2];
		dz := arr[i1,3]-arr[i2,3];
		R[i1,i2] := sqrt(dx*dx+dy*dy+dz*dz); {}
		Rij := R[i1,i2];
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
			if ((arr[i1,4]>0)and(arr[i2,4]>0))or((arr[i1,4]<0)and(arr[i2,4]<0)) then 
				{Vr := B*power(bb/R[i1,i2], 12) {}
				Vr :=arr[i1,4]*arr[i2,4]/R[i1,i2]{}
			else
				{Vr := A*(power(aa/R[i1,i2], 12) - power(aa/R[i1,i2], 6)){}
				Vr :=arr[i1,4]*arr[i2,4]/R[i1,i2] + B/power(R[i1,i2],9){}
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
			for j:=i+1 to n1+n2 do
				rez := rez + Vr(i,j);
		E := rez;
	end;
	procedure pereschet_R(k:word);
	var
		i:word;
	begin
		for i := 0 to k-1 do Rij(i,k);
		for i := k+1 to n1+n2 do Rij(k,i);
	end;
	procedure relax;
	var
		dx,dy,dz, curr_E, prev_E :double;
		napr, k :word;
		i:longint;
		f:text;
	begin
		assign(f, 'out.txt'); rewrite(f);
		prev_E := E;
		for i:=1 to 100000 do
		begin
			k := random(n1+n2) + 1;
			napr := random(3) + 1;{выбираем случайное направление }
			dx := (random(10000) - 50000) / 4000000; {случайное смещение }
			dy := (random(10000) - 50000) / 4000000; 
			dz := (random(10000) - 50000) / 4000000; 
			{arr[k, napr] := arr[k, napr] + dx; {}
			arr[k, 1] := arr[k, 1] + dx;
			arr[k, 2] := arr[k, 2] + dy;
			arr[k, 3] := arr[k, 3] + dz;
			{}
			pereschet_R(k);
			curr_E :=E;
			if(((curr_E<0)and(prev_E>0))or((curr_E>0)and(prev_E<0))) then break;
			if((((prev_E - curr_E)<0) and(prev_E>0))or(((prev_E - curr_E)>0) and(prev_E<0))) then
			begin
				{arr[k, napr] := arr[k, napr] - d;{}
				arr[k, 1] := arr[k, 1] - dx;
				arr[k, 2] := arr[k, 2] - dy;
				arr[k, 3] := arr[k, 3] - dz;{}
				pereschet_R(k);
			end
			else
				prev_E := curr_E;
			writeln(f,E:0:10);{}
		end;
		close(f);
	end;
	procedure maple_out;
	var
		i:word;
		fm:text;
	begin
		assign(fm,'maple.mpl'); rewrite(fm);
		writeln(fm, 'with(plots,Interactive,pointplot3d);'
			,#13#10'pointplot3d({');
		for i :=0 to n1+n2-1 do
		begin
			writeln(fm, '[', arr[i,1]:0:10,', ',
				arr[i,2]:0:10,', ',
				arr[i,3]:0:10,'], #',R[0,i]:0:4);
		end;
		writeln(fm,'[', arr[n1+n2,1]:0:10,', ',
			arr[n1+n2,2]:0:10,', ',
			arr[n1+n2,3]:0:10,']},axes=normal,symbol=circle,symbolsize=14); #',R[0,n1+n2]:0:4);
		close(fm);
	end;
begin
	randomize;
	random_array;
	relax;
	maple_out;
	{readln;{}
end.