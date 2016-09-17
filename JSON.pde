public ArrayList<Agent> loadJSONAgents(String JSONFile, Roads roads) {

    ArrayList<Agent> agents = new ArrayList();
    
    File file = new File(dataPath(JSONFile));
    if (!file.exists()) println("ERROR");
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
            
                Agent agent = new Agent(agents.size() , roads);
                agent.setStyle(size, tint);
                agents.add(agent);
            }
            
        }
    }
    
    return agents;

}