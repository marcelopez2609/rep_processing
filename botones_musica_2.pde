import controlP5.*;
import ddf.minim.*;

import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

import java.util.*;
import java.net.InetAddress;
import javax.swing.*;
import javax.swing.filechooser.FileFilter;
import javax.swing.filechooser.FileNameExtensionFilter;

import org.elasticsearch.action.admin.indices.exists.indices.IndicesExistsResponse;
import org.elasticsearch.action.admin.cluster.health.ClusterHealthResponse;
import org.elasticsearch.action.index.IndexRequest;
import org.elasticsearch.action.index.IndexResponse;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.action.search.SearchType;
import org.elasticsearch.client.Client;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.node.Node;
import org.elasticsearch.node.NodeBuilder;

static String INDEX_NAME = "canciones";
static String DOC_TYPE = "cancion";

ControlP5 ui;
ControlP5 cp5;

Client client;
Node node;

Minim minim;

AudioPlayer song;
AudioMetaData meta;

FFT fft;

HighPassSP banalt;
LowPassSP banbaj;
BandPass banmed;

ControlP5 selection;
ControlP5 cbars;
ScrollableList list;

/*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°*/

int sliderValue =0;
float r=6.0206;
float a[]=new float [100];

String author = "" ;
String title = "";


int f1;
int f2;
int f3;
int duration = 10;
boolean selec;

/*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°*/

void setup() {

  size(550, 300);
  fill(0);
  noStroke();

  Settings.Builder settings = Settings.settingsBuilder();

  settings.put("path.data", "esdata");
  settings.put("path.home", "/");
  settings.put("http.enabled", false);
  settings.put("index.number_of_replicas", 0);
  settings.put("index.number_of_shards", 1);

  node = NodeBuilder.nodeBuilder()
    .settings(settings)
    .clusterName("mycluster")
    .data(true)
    .local(true)
    .node();

  client = node.client();

  ClusterHealthResponse r = client.admin().cluster().prepareHealth().setWaitForGreenStatus().get();

  IndicesExistsResponse ier = client.admin().indices().prepareExists(INDEX_NAME).get();
  if (!ier.isExists()) {
    client.admin().indices().prepareCreate(INDEX_NAME).get();
  }


  ui = new ControlP5(this);

  ui.addButton("play")
    .setPosition(100, 280)
    .setSize(65, 65)
    .setImages(loadImage("play.png"), loadImage("play.png"), loadImage("play.png"));

  ui.addButton("pause")
    .setPosition(50, 280)
    .setSize(50, 50)
    .setImages(loadImage("pause.png"), loadImage("pause.png"), loadImage("pause.png"));

  ui.addButton("stop")
    .setPosition(150, 280)
    .setSize(50, 50)
    .setImages(loadImage("stop.png"), loadImage("stop.png"), loadImage("stop.png"));

  selection = new ControlP5(this);
  selection.addButton("selections")
    .setPosition(200, 280)
    .setSize(50, 10)
    .setColorBackground(color(30, 30, 30));


  ui.addSlider("Vol.")
    .setPosition(270, 280)
    .setSize(120, 10)
    .setRange(0, 100)
    .setValue(50)
    .setColorBackground(color(30, 30, 30));

  ui.addSlider("f1")
    .setPosition(420, 288)
    .setSize(110, 5)
    .setRange(0, 3000)
    .setValue(10)
    .setLabelVisible(false)
    .setColorBackground(color(30));

  ui.addSlider("f2")
    .setPosition(420, 278)
    .setSize(110, 5)
    .setRange(30000, 200000)
    .setValue(10)
    .setLabelVisible(false)
    .setColorBackground(color(30));

  ui.addSlider("f3")
    .setLabelVisible(true)
    .setPosition(420, 268)
    .setSize(110, 5)
    .setRange(100, 1000)
    .setValue(10)
    .setLabelVisible(false)
    .setColorBackground(color(30));
  /*
  ui.addSlider("")
   .setPosition(10, 234)
   .setSize(380, 4)
   .setRange(0, 1000000)
   .setValue(0)
   .setLabelVisible(false)
   .setColorBackground(color(30));
   */

  list = ui.addScrollableList("playlist")
    .setPosition(400, 0)
    .setSize(150, 230)
    .setBarHeight(20)
    .setItemHeight(20)
    .setType(ScrollableList.LIST)
    .setColorBackground(color(0));

  loadFiles();
}

/*°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°*/

void draw() {

  noStroke();
  fill(0);
  rect(0, 242, 550, 60);
  rect(0, 0, 400, 242);
  rect(400, 0, 150, 250);
  
  fill(250);
  // ellipse(103, 283, 20,  20);
  rect(89, 276, 30, 15);
  rect(39, 276, 30, 15);
  rect(139, 276, 30, 15);



  fill(255);
  textSize(10);
  text("Titulo : ", 5, 260);
  text("Autor : ", 199, 260);
  textSize(10);
  text("ecualizador", 433, 260);

  if (song != null) {
    if (song.isPlaying()) {

      textSize(10);
      text("Titulo : " + meta.title(), 5, 260);
      text("Autor : " + meta.author(), 199, 260);

      ui.addSlider("")
        .setPosition(10, 234)
        .setSize(380, 4)
        .setRange(0, song.length())
        .setValue(0)
        .setLabelVisible(false)
        .setColorBackground(color(30));


      banalt.setFreq(f1);
      banbaj.setFreq(f2);
      banmed.setFreq(f3);


      ui.getController("").setValue(song.position());
      stroke(255);
      fft.forward(song.mix);
      for (int i = 0; i<400 /*fft.specSize()*/; i++) {
        float band = fft.getBand(i); 
        float tam =  220 - band*4;
        line(i, 220, i, tam);
      }
    }
  }
}



public void selections() {

  JFileChooser jfc = new JFileChooser();
  jfc.setFileFilter(new FileNameExtensionFilter("MP3 File", "mp3"));
  jfc.setMultiSelectionEnabled(true);
  jfc.showOpenDialog(null);
  println("antes del for");
  for (File f : jfc.getSelectedFiles()) {
    GetResponse response = client.prepareGet(INDEX_NAME, DOC_TYPE, f.getAbsolutePath()).setRefresh(true).execute().actionGet();
    println("if");
    if (response.isExists()) {
      println(":@");
      continue;
    }
    //minim.stop();
    println("despues del for");
    minim = new Minim(this);
    song = minim.loadFile(f.getAbsolutePath());
    meta = song.getMetaData();

    Map<String, Object> doc = new HashMap<String, Object>();
    doc.put("author", meta.author());
    doc.put("title", meta.title());
    doc.put("path", f.getAbsolutePath());

    try {
      client.prepareIndex(INDEX_NAME, DOC_TYPE, f.getAbsolutePath())
        .setSource(doc)
        .execute()
        .actionGet();

      addItem(doc);
    } 
    catch(Exception e) {
      e.printStackTrace();
    }
  }

  fft = new FFT(song.bufferSize(), song.sampleRate());
  banalt= new HighPassSP (300, song.sampleRate());
  song.addEffect(banalt);
  banbaj =new LowPassSP (300, song.sampleRate());
  song.addEffect(banbaj);
  banmed = new BandPass (300, 300, song.sampleRate());
  song.addEffect(banmed);
}


public void play() {
  song.play();
}

public void pause() {
  song.pause();
}

public void alto() {
  song.pause();
  song.rewind();
  song.cue(0);
}

/*
public void cargar() {
 selectInput("Select a file to process:", "fileSelected");
 }
 */

public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
}


void fileSelected(File selection) {
  if (selection != null) {
    minim.stop();
    song = minim.loadFile(selection.getAbsolutePath(), 1024);
    meta = song.getMetaData();
    fft = new FFT(song.bufferSize(), song.sampleRate());

    banalt= new HighPassSP (300, song.sampleRate());
    song.addEffect(banalt);
    banbaj =new LowPassSP (300, song.sampleRate());
    song.addEffect(banbaj);
    banmed = new BandPass (300, 300, song.sampleRate());
    song.addEffect(banmed);



    selec = true;
  } else {
    if (song.isPlaying()) {
    }
    println("Window was closed or the user hit cancel. ");
  }
}


void playlist(int n) {
  Map<String, Object> value = (Map<String, Object>) list.getItem(n).get("value");
  println(value.get("path"));
  //println(list.getItem(n));
}




void loadFiles() {
  try {
    SearchResponse response = client.prepareSearch(INDEX_NAME).execute().actionGet();
    for (SearchHit hit : response.getHits().getHits()) {
      addItem(hit.getSource());
    }
  } 
  catch(Exception e) {
    e.printStackTrace();
  }
}

void addItem(Map<String, Object> doc) {
  list.addItem(doc.get("author") + " - " + doc.get("title"), doc);
}


void volumen(float theColor) {

  float mycolor=theColor;

  for (int i=0; i<30; i++) {
    a[i]=theColor;
    //x=song.getGain()+ theColor;
    if (a[i+1]<a[i]) {
      a[i+1]=song.getGain()+ theColor;
      song.setGain( song.getGain()+mycolor);
      println(a[i]);
    } else if (  a[i+1]>a[i]) {
      a[i+1]=song.getGain()- theColor;
      song.setGain( song.getGain()- mycolor);
    }
    println("Volumen "+a[i]);
  }
}