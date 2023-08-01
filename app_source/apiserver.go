package main

import (
	"encoding/json"
	"fmt"
	"log"
	//"mime"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
	"flag"
	"math/rand"
)

var (
    infoLog   *log.Logger
    errLog    *log.Logger
)

func init() {
	infoLog = log.New(os.Stdout, "INFO\t", log.Ldate|log.Ltime)
	errLog = log.New(os.Stderr, "ERROR\t", log.Ldate|log.Ltime|log.Lshortfile)
}

func renderJSON(w http.ResponseWriter, v interface{}) {
  js, err := json.Marshal(v)
  if err != nil {
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
	if req.URL.Path == "/task/" {
		// Request is plain "/task/", without trailing ID.
		if req.Method == http.MethodPost {

		} else if req.Method == http.MethodGet {

		} else if req.Method == http.MethodDelete {

		} else {
			http.Error(w, fmt.Sprintf("expect method GET, DELETE or POST at /task/, got %v", req.Method), http.StatusMethodNotAllowed)
			return
		}
	} else {
		// Request has an ID, as in "/task/<id>".
		path := strings.Trim(req.URL.Path, "/")
		pathParts := strings.Split(path, "/")
		if len(pathParts) < 2 {
			http.Error(w, "expect /task/<id> in task handler", http.StatusBadRequest)
			return
		}
		id, err := strconv.Atoi(pathParts[1])
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		infoLog.Println(id)

		if req.Method == http.MethodDelete {

		} else if req.Method == http.MethodGet {

		} else {
			http.Error(w, fmt.Sprintf("expect method GET or DELETE at /task/<id>, got %v", req.Method), http.StatusMethodNotAllowed)
			return
		}
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"response":"ok"}`))
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
	mux.HandleFunc("/task/", taskHandler)
	mux.HandleFunc("/wait/", waitHandler)

	errLog.Fatal(http.ListenAndServe(*addr, mux))
}
