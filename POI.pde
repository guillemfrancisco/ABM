// POI FACADE -------------->
public class PointsOfInterest extends Facade {

    public PointsOfInterest(PApplet papplet, Roads roadmap) {
        super(papplet, roadmap);
        factory = new POIFactory();
    }
    
}


// POI Factory -------------->
private class POIFactory extends Factory {
    
    public ArrayList<POI> loadFromJSON(File JSONFile, Roads roads) {
        
        ArrayList<POI> pois = new ArrayList();
        int count = count();
        
        JSONArray clusters = loadJSONArray(JSONFile);
        for(int i = 0; i < clusters.size(); i++) {
            JSONObject cluster = clusters.getJSONObject(i);
            
            String type        = cluster.getString("type");
            String clusterName = cluster.getString("name");
            JSONObject style   = cluster.getJSONObject("style");
            String tint        = style.getString("color");
            int size           = style.getInt("size");
            
            JSONArray items   = cluster.getJSONArray("items");
            for(int j = 0; j < items.size(); j++) {
                JSONObject item = items.getJSONObject(j);
                
                int id              = item.getInt("id");
                String name         = item.getString("name");
                PVector location    = roads.toXY(
                                        item.getJSONArray("location").getFloat(0),
                                        item.getJSONArray("location").getFloat(1)
                                    );
                int capacity        = item.getInt("capacity");
                JSONArray languages = item.getJSONArray("languages");
                
                if( location.x > 0 && location.x < width && location.y > 0 && location.y < height ) {
                    pois.add( new POI(roads, count, location, name, capacity) );
                    counter.increment(clusterName);
                    count++;
                }
                
            }
        }

        return pois;
        
    }
      
     
    public ArrayList<POI> loadFromCSV(String path, Roads roads) {
        
        print("Loading POIs... ");
        
        ArrayList<POI> pois = new ArrayList();
        int count = count();
        
        Table table = loadTable(path, "header, tsv");
        for(TableRow row : table.rows()) {
            
            String name         = row.getString("NAME");
            PVector location    = roads.toXY(row.getFloat("LAT"), row.getFloat("LNG"));
            int capacity        = row.getInt("CAPACITY");
            int size            = 3;
            
            if( location.x > 0 && location.x < width && location.y > 0 && location.y < height ) {
                pois.add( new POI(roads, count, location, name, capacity) );
                counter.increment(path); 
                count++;
            }
        }
        
        println("LOADED");
        return pois;
    }
     
}



// POI CLASSES -------------->
public class POI implements Placeable {

    private final int ID;
    private final String NAME;
    private final PVector POSITION;
    private final Node NODE;
    private final int CAPACITY;
    
    private ArrayList<Agent> crowd = new ArrayList();
    private float occupancy;
    private boolean selected;
    
    
    public POI(Roads roadmap, int id, PVector position, String name, int capacity) {
        ID = id;
        NAME = name;
        CAPACITY = capacity;
        NODE = roadmap.connect(position);
        POSITION = position;
    }
    
    
    public PVector getPosition() {
        return POSITION;
    }
    
    
    public Node getNode() {
        return NODE;
    }
    
    
    public boolean host(Agent agent) {
        if(crowd.size() < CAPACITY) {
            crowd.add(agent);
            occupancy = (float)crowd.size() / CAPACITY;
            return true;
        }
        return false;
    }
    
    public void unhost(Agent agent) {
        crowd.remove(agent);
        occupancy = (float)crowd.size() / CAPACITY;
    }
    
    
    public void draw() {
        
        color c = lerpColor(#00FF00, #FF0000, occupancy);
        float size = (5 + 10 * occupancy);
        
        stroke(c, 100); strokeWeight(2); noFill(); rectMode(CENTER);
        rect(getPosition().x, getPosition().y, size, size);
        point(POSITION.x, POSITION.y);
        
        if( selected ) {
            fill(0); textAlign(CENTER, BOTTOM);
            text(this.toString(), POSITION.x, POSITION.y + 20);
        }

    }


    public void select(int mouseX, int mouseY) {
        selected = dist(POSITION.x, POSITION.y, mouseX, mouseY) < 5;
    }
    
    
    public String toString() {
        return NAME + " [" + crowd.size() + " / " + CAPACITY + "]";
    }
    

}