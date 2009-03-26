{$A+,B-,D-,E+,F-,G-,I+,L-,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y-}
{$M 16384,0,655360}
uses crt;
const
	n0 = 1; r0 = 0; q0 = +2;
	n1 = 8; r1 = 3; q1 = -4;
	n2 = 1; r2 = 5; q2 = +3;
	pi = 3.1459;
	pi_2 = pi/2;
	pi10000 = 31459;
	rh = 0.529;
	B=43;
type
	TArr = array[0..n1+n2,0..4] of double;
var
	f:text;
	arr:TArr;
	function ArcSin( x:double):double;
	begin
		ArcSin:=Arctan(x/Sqrt(1-x*x));
	end;
	procedure random_array;
	var 
		i : word;
		phi, tetta : double;
	begin
		arr[0,0] = r0; arr[0,1] = 0; arr[0,2] = 0; arr[0,3] = 0; 
		arr[0,4] = q0; 
		for i:=1 to n1 do 
		begin
			phi := random(pi10000+pi10000)/10000;
			tetta := ArcSin(2 * random(10000)/10000 - 1) + pi_2;{}
			arr[i,0] := r1;
			arr[i,1] := r1*sin(tetta)*cos(phi);
			arr[i,2] := r1*sin(tetta)*sin(phi);
			arr[i,3] := r1*cos(tetta);
			arr[i,4] := q1;
		end;
		for i:=n1+1 to n1+n2 do 
		begin
			phi := random(pi10000+pi10000)/10000;
			tetta := ArcSin(2 * random(10000)/10000 - 1) + pi_2;{}
			arr[i,0] := r2;
			arr[i,1] := r2*sin(tetta)*cos(phi);
			arr[i,2] := r2*sin(tetta)*sin(phi);
			arr[i,3] := r2*cos(tetta);
			arr[i,4] := q2;
		end;
	end;
	
	function E : double;
	var
		i,j:word;
		r: double;
	begin
		E :=0;
		for i :=1 to n1+n2 do
		begin
			writeln(f, '[', arr[i,1]:0:10,', ',
							arr[i,2]:0:10,', ',
							arr[i,3]:0:10,'],');
		end;
		for i :=0 to n1+n2 do
			for j:=i+1 to n1+n2 do
				E := E + Vr(i,j);
			end;
	end;
	function Vr(i1,i2: word) : double;
	var 
		Rij,dx,dy,dy:double;
	begin
		dx = arr[i1,1]-arr[i2,1];
		dy = arr[i1,2]-arr[i2,2];
		dz = arr[i1,3]-arr[i2,3];
		Rij := sqrt(dx*dx+dy*dy+dz*dz);
		Vr := arr[i1,4]*arr[i2,4]/Rij+B*power(Rij,7);
	end;
	function power(x: double, n:word) : double;
	var 
		i:word;
	begin
		for i:=1 to n do power := power * x;
	end;

begin
	assign(f, 'out.txt'); rewrite(f);
	randomize;
	random_array;
	E;
	Vr(1,4);
	write('hello world');
	close(f);
	{readln;{}
end.