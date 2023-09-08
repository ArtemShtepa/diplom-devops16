package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
	"flag"
	"math/rand"
	"golang.org/x/exp/slices"
	"github.com/google/uuid"
)

var (
	infoLog      *log.Logger
	errLog       *log.Logger
	Instance_id   string
	Version = "Unknown"
)

func init() {
	infoLog = log.New(os.Stdout, "INFO\t", log.Ldate|log.Ltime)
	errLog = log.New(os.Stderr, "ERROR\t", log.Ldate|log.Ltime|log.Lshortfile)
	Instance_id = uuid.New().String()
}

func renderJSON(w http.ResponseWriter, v interface{}) {
	js, err := json.Marshal(v)
	if err != nil {
		errLog.Printf("Can't encode JSON block: %s", err.Error())
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(js)
}

func rootHandler(w http.ResponseWriter, req *http.Request) {
	type Message struct {
		Method string `json:"method"`
		Path string
	}

	infoLog.Println("Request", req.Method, req.URL.Path)
	m := Message{req.Method, req.URL.Path}

	renderJSON(w, m)
}

func uuidHandler(w http.ResponseWriter, req *http.Request) {
	type Message struct {
		Version string
		Uuid string `json:"UUId"`
	}
	var m Message

	m.Version = Version
	m.Uuid = Instance_id

	renderJSON(w, m)
}

func ipHandler(w http.ResponseWriter, req *http.Request) {
	l := []string{}

	ifaces, err := net.Interfaces()
	if err == nil {
		for _, i := range ifaces {
			addrs, err := i.Addrs()
			if err == nil {
				for _, a := range addrs {
					switch v := a.(type) {
					case *net.IPAddr:
						infoLog.Printf("%v : %s (%s)\n", i.Name, v, v.IP.DefaultMask())
						if i.Name != "lo" {
							l = append(l, fmt.Sprintf("%s", v.IP))
						}
					case *net.IPNet:
						infoLog.Printf("%v : %s [%v/%v]\n", i.Name, v, v.IP, v.Mask)
						if i.Name != "lo" {
							l = append(l, fmt.Sprintf("%s", v.IP))
						}
					}
				}
			} else {
				errLog.Printf("Decode interface address: %s", err.Error())
			}
		}
	} else {
		errLog.Printf("Acquire network interfaces: %s", err.Error())
	}
	host, err := os.Hostname()
	if err == nil {
		addrs, err := net.LookupIP(host)
		if err == nil {
			for _, addr := range addrs {
				if ipv4 := addr.To4(); ipv4 != nil {
					p := fmt.Sprintf("%s", ipv4)
					infoLog.Printf("Hostname lookup: %s", p)
					if ! slices.Contains(l, p) {
						l = append(l, fmt.Sprintf("%s", ipv4))
					}
				}
			}
		} else {
			errLog.Printf("Lookup IP from hostname: %s", err.Error())
		}
	} else {
		errLog.Printf("Acquire hostname: %s", err.Error())
	}

	renderJSON(w, l)
}

func waitHandler(w http.ResponseWriter, req *http.Request) {
	type Message struct {
		time_start   time.Time
		time_finish  time.Time
		Start    string
		Finish   string
		UnixStart  int64
		UnixFinish int64
	}
	var m Message

	m.time_start = time.Now()
	rand.Seed(time.Now().UnixNano())
	time.Sleep(time.Second + time.Duration(rand.Int63n(4000)) * time.Millisecond)
	m.time_finish = time.Now()
	m.Start = m.time_start.String()
	m.Finish = m.time_finish.String()
	m.UnixStart = m.time_start.Unix()
	m.UnixFinish = m.time_finish.Unix()

	renderJSON(w, m)
}

func taskHandler(w http.ResponseWriter, req *http.Request) {
	type Message struct {
		Id int `json:"id"`
	}
	var m Message
	if req.URL.Path == "/task/" {
		if req.Method == http.MethodPost || req.Method == http.MethodGet {

		} else {
			errLog.Printf("Request method: %s", req.Method)
			http.Error(w, fmt.Sprintf("Expect method GET or POST at /task/, got %v", req.Method), http.StatusMethodNotAllowed)
			return
		}
	} else {
		path := strings.Trim(req.URL.Path, "/")
		pathParts := strings.Split(path, "/")
		if len(pathParts) < 2 {
			errLog.Printf("Path length in request: %v", len(pathParts))
			http.Error(w, "Expect /task/<id> in task handler", http.StatusBadRequest)
			return
		} else {
			id, err := strconv.Atoi(pathParts[1])
			if err != nil {
				errLog.Printf("Decode task id: %s, %s", pathParts[1], err.Error())
				http.Error(w, fmt.Sprintf("Expect numeric task id: %s", err.Error()), http.StatusBadRequest)
				return
			} else {
				m.Id = id
				infoLog.Printf("Accept task id: %v", m.Id)
				if req.Method == http.MethodGet {

				} else if req.Method == http.MethodPost {

				} else if req.Method == http.MethodDelete {

				} else {
					errLog.Printf("Request method: %s", req.Method)
					http.Error(w, fmt.Sprintf("Expect method GET, POST or DELETE at /task/<id>, got %v", req.Method), http.StatusMethodNotAllowed)
					return
				}
			}
		}
	}
	renderJSON(w, m)
}

func main() {
	var addr_def string = os.Getenv("API_BIND")
	if addr_def == "" {
		addr_def = ":8080"
	}
	addr := flag.String("addr", addr_def, "Address on which server will listen for requests")
	flag.Parse()

	infoLog.Println("Listen on", *addr)

	mux := http.NewServeMux()
	mux.HandleFunc("/", rootHandler)
	mux.HandleFunc("/uuid", uuidHandler)
	mux.HandleFunc("/ip", ipHandler)
	mux.HandleFunc("/task/", taskHandler)
	mux.HandleFunc("/wait", waitHandler)

	errLog.Fatal(http.ListenAndServe(*addr, mux))
}
