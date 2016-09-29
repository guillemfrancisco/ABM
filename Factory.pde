public class AgentFactory {
    
    IntDict counter = new IntDict();
    
    /*
    IntDict counter = af.counter;
    int i = 0;
    for(String name : counter.keys()) {
        text(name + ": " + counter.get(name) + " agents", 20, 70 + 15*i);
        i++;
    }
    */
    
    public ArrayList<Agent> loadFromJSON(String JSONFile, Roads roads) {
    
        ArrayList<Agent> agents = new ArrayList();
        
        File file = new File( dataPath(JSONFile) );
        if (!file.exists()) println("ERROR! " + JSONFile + " does not exist");
        else {
            
            JSONArray clusters = loadJSONObject(file).getJSONArray("clusters");
            for(int i = 0; i < clusters.size(); i++) {
                JSONObject cluster = clusters.getJSONObject(i);
                
                int id            = cluster.getInt("id");
                String name       = cluster.getString("name");
                String type       = cluster.getString("type");
                int amount        = cluster.getInt("amount");
                
                JSONObject style  = cluster.getJSONObject("style");
                String tint       = style.getString("color");
                int size          = style.getInt("size");
                
                for(int j = 0; j < amount; j++) {
                    Agent agent = null;
                    
                    if( type.equals("PERSON") ) agent = new Person(agents.size(), roads);
                    else if( type.equals("CAR") ) agent = new Car(agents.size(), roads);
                    
                    if(agent != null) {
                        agent.setStyle(size, tint);
                        agents.add(agent);
                        counter.increment(name);
                    }
                    
                }
                
            }
        }
        
        return agents;
    
    }

}