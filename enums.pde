public enum Visibility { HIDE, SHOW, TOGGLE; }


public enum Accessible {
    WALK {
        @Override
        public boolean allows(Agent agent) {
            return agent instanceof Person;
        }
    },
    DRIVE {
        @Override
        public boolean allows(Agent agent) {
            return agent instanceof Vehicle;
        }
    },
    ALL {
        @Override
        public boolean allows(Agent agent) {
            return true;
        }
    };
    
    public abstract boolean allows(Agent agent);
    
    public static Accessible create(String name) {
        switch(name) {
            // Road types
            case "primary": case "secondary": case "residential": case "service": return ALL;
            case "pedestrian": case "living_street": case "footway": case "steps": case "cycleway": return WALK;
            case "tunnel": return DRIVE;
            // POI types
            case "hotel": case "restaurant": case "bar": case "museum": return WALK;
            case "parking": return DRIVE;
        }
        return ALL;
    }
}