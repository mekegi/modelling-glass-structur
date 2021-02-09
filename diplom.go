package main

import (
	"bufio"
	"embed"
	"fmt"
	"io/fs"
	"io/ioutil"
	"math"
	"math/rand"
	"net/http"
	"os"
	"strings"
	"time"
)

const (
	pi      = 3.1459
	pi_2    = pi / 2
	pi10000 = 31459 //{чтобы в цикле не вычислять выражение 10000*пи}
	n       = 20    //{максимальное количество частиц}

	head = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE X3D PUBLIC "ISO//Web3D//DTD X3D 3.0//EN" "https://www.web3d.org/specifications/x3d-3.0.dtd">
<X3D profile='Immersive' version='3.0' xmlns:xsd='http://www.w3.org/2001/XMLSchema-instance' xsd:noNamespaceSchemaLocation='https://www.web3d.org/specifications/x3d-3.0.xsd'>
    <head>
        <meta content='ololo.x3d' name='title'/>
    </head>
    <Scene>
        <Viewpoint description='View shape' position='0 0 6'/>
`
	foot = `
	</Scene>
</X3D>
`
	tmpl = `
	<Transform translation='%.10f  %.10f  %.10f'>
        <Shape>
            <Sphere radius='%.10f' />
            <Appearance>
                <Material diffuseColor='%s' />
            </Appearance>
        </Shape>
    </Transform>
`
)

type relaxModel struct {
	a    tArr
	c    conf
	lazy [][]float64
}

type tArr []point

func (rm *relaxModel) relax() {
	h := 0.3
	check := int64(0)

	prevE := rm.E()
	sumE := 0.0
	for i := int64(0); i < rm.c.MaxIter; i++ {
		k := rand.Intn(len(rm.a)-1) + 1
		prevP := rm.a[k]
		rm.a[k].X += (rand.Float64() - 0.5) * h
		rm.a[k].Y += (rand.Float64() - 0.5) * h
		rm.a[k].Z += (rand.Float64() - 0.5) * h
		rm.reCalcDistance(k)
		curE := rm.E()

		if curE > prevE {
			rm.a[k] = prevP
			rm.reCalcDistance(k)
			continue
		}
		sumE += curE - prevE
		prevE = curE
		check++
		if (check == 9) || (check == 90) ||
			(check == 200) || check == 500 || check == 1000 {
			h /= 2
		}

		if i%100 == 0 {
			sumE = 0.0
		}
	}
	fmt.Printf("sumE = %.8f\n", sumE)
}

func (rm *relaxModel) webGLOut() string {
	res := head
	for i := range rm.a {
		res += rm.a[i].x3d()
	}
	res += foot
	return res
}

func (rm *relaxModel) Vr(i, j int) float64 {
	if i > j {
		return 0
	}
	ft := 5
	if i == 0 {
		if rm.a[j].Q == rm.c.Q1 {
			ft = 1
		} else {
			ft = 2
		}
	} else if rm.a[i].Q == rm.a[j].Q {
		if rm.a[j].Q == rm.c.Q1 {
			ft = 3
		} else {
			ft = 4
		}
	}
	R := rm.lazy[i][j] // rm.a[i].Distance(rm.a[j])
	c1, c2, c3 := rm.c.Cnst[ft][1], rm.c.Cnst[ft][2], rm.c.Cnst[ft][3]
	aj_R := float64(rm.a[i].Q*rm.a[j].Q) / R
	switch rm.c.Ftype[ft] {
	case 1:
		return c1*aj_R + c2*math.Exp(R/c3)
	case 2:
		return c1*aj_R + c2*math.Pow(R/c3, -8)
	case 3:
		return c1*math.Pow(R/c2, -12) - math.Pow(R/c2, -6)
	case 4:
		return c1 * math.Pow(R/c2, -12)
	case 5:
		return c1*aj_R + c2*math.Pow(R/c3, -12)
	}
	return 0

}
func (rm *relaxModel) E() float64 {
	e := 0.0
	for i := range rm.a {
		for j := i + 1; j < len(rm.a); j++ {
			e += rm.Vr(i, j)
		}
	}
	return e
}

func (rm *relaxModel) reCalcDistance(k int) {
	for i := 0; i < k; i++ {
		rm.lazy[i][k] = rm.a[i].Distance(rm.a[k])
		rm.lazy[k][i] = rm.lazy[i][k]
	}
	for i := k + 1; i < len(rm.a); i++ {
		rm.lazy[k][i] = rm.a[i].Distance(rm.a[k])
		rm.lazy[i][k] = rm.lazy[k][i]
	}
}
func (rm *relaxModel) fileName() string {
	return fmt.Sprintf("WRL/_%d_%d.x3d", rm.c.N1, rm.c.N2)
}

type point struct {
	X      float64
	Y      float64
	Z      float64
	Q      int // charge
	Color  string
	Radius float64
}

func (p point) x3d() string {
	return fmt.Sprintf(tmpl, p.X, p.Y, p.Z,
		p.Radius,
		p.Color,
	)
}

type conf struct {
	MaxIter            int64
	Debug, R1, R2      float64
	Q0, N1, Q1, N2, Q2 int
	Ftype              [6]byte
	Color              [3]string
	Rview              [3]float64
	Cnst               [6][4]float64 // {константы}
}

func (p point) Distance(to point) float64 {
	dx := p.X - to.X
	dy := p.Y - to.Y
	dz := p.Z - to.Z
	return math.Sqrt(dx*dx + dy*dy + dz*dz)
}

func randomRelaxModel(c conf) *relaxModel {
	a := make(tArr, 0, 1+c.N1+c.N2)
	a = append(a, point{
		X:      0,
		Y:      0,
		Z:      0,
		Q:      c.Q0,
		Radius: c.Rview[0],
		Color:  c.Color[0],
	})
	for i := 0; i < c.N1; i++ {
		phi := float64(rand.Int63n(pi10000+pi10000)) / 10000.0
		tetta := math.Asin(2*float64(rand.Int63n(10000))/10000.0-1) + pi_2
		a = append(a, point{
			X:      c.R1 * math.Sin(tetta) * math.Cos(phi),
			Y:      c.R1 * math.Sin(tetta) * math.Sin(phi),
			Z:      c.R1 * math.Cos(tetta),
			Q:      c.Q1,
			Radius: c.Rview[1],
			Color:  c.Color[1],
		})
	}
	for i := 0; i < c.N2; i++ {
		phi := float64(rand.Int63n(pi10000+pi10000)) / 10000.0
		tetta := math.Asin(2*float64(rand.Int63n(10000))/10000.0-1) + pi_2
		a = append(a, point{
			X:      c.R2 * math.Sin(tetta) * math.Cos(phi),
			Y:      c.R2 * math.Sin(tetta) * math.Sin(phi),
			Z:      c.R2 * math.Cos(tetta),
			Q:      c.Q2,
			Radius: c.Rview[2],
			Color:  c.Color[2],
		})
	}

	result := relaxModel{
		a:    a,
		c:    c,
		lazy: make([][]float64, len(a)),
	}
	for i := range result.lazy {
		result.lazy[i] = make([]float64, len(a))
	}

	return &result
}

func readConstant(s string) conf {
	res := conf{}
	f, _ := os.Open(s)
	defer f.Close()
	scanner := bufio.NewScanner(f)
	scanner.Split(bufio.ScanLines)
	fmt.Fscan(f, &res.MaxIter, &res.Debug)
	fmt.Fscan(f, &res.Q0)
	fmt.Fscan(f, &res.N1, &res.R1, &res.Q1)
	fmt.Fscan(f, &res.N2, &res.R2, &res.Q2)
	scanner.Scan()
	for i := range res.Color {
		scanner.Scan()
		res.Color[i] = strings.TrimSpace(scanner.Text())
	}
	scanner.Scan()
	fmt.Sscan(scanner.Text(), &res.Rview[0], &res.Rview[1], &res.Rview[2])
	scanner.Scan()
	fmt.Sscan(scanner.Text(), &res.Ftype[1], &res.Cnst[1][1], &res.Cnst[1][2], &res.Cnst[1][3])
	scanner.Scan()
	fmt.Sscan(scanner.Text(), &res.Ftype[2], &res.Cnst[2][1], &res.Cnst[2][2], &res.Cnst[2][3])
	scanner.Scan()
	fmt.Sscan(scanner.Text(), &res.Ftype[3], &res.Cnst[3][1], &res.Cnst[3][2], &res.Cnst[3][3])
	scanner.Scan()
	fmt.Sscan(scanner.Text(), &res.Ftype[4], &res.Cnst[4][1], &res.Cnst[4][2], &res.Cnst[4][3])
	scanner.Scan()
	fmt.Sscan(scanner.Text(), &res.Ftype[5], &res.Cnst[5][1], &res.Cnst[5][2], &res.Cnst[5][3])

	return res
}

//go:embed WRL/*
var embededFiles embed.FS

func getFileSystem() http.FileSystem {
	fsys, err := fs.Sub(embededFiles, "WRL")
	if err != nil {
		panic(err)
	}

	return http.FS(fsys)
}
func main() {
	go func() {
		rand.Seed(time.Now().UnixNano())

		conf := readConstant("input.txt")

		for conf.N1 = 4; conf.N1 < 9; conf.N1++ {
			nj := 3
			if conf.N1 > 5 {
				nj = 4
			}
			for conf.N2 = 0; conf.N2 <= nj; conf.N2++ {
				model := randomRelaxModel(conf)
				model.relax()
				ioutil.WriteFile(model.fileName(), []byte(model.webGLOut()), os.ModeExclusive)
				fmt.Println("writed: ", model.fileName())
			}
		}
	}()

	http.Handle("/", http.FileServer(getFileSystem()))
	fmt.Println("start listening http://127.0.0.1:8888/")
	http.ListenAndServe(":8888", nil)
}
