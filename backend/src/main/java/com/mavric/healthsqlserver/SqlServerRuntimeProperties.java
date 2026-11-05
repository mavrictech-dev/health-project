package com.mavric.healthsqlserver;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.ConstructorBinding;

/** External runtime inputs only. Validation and diagnostic text never include input values. */
@ConfigurationProperties("health.sqlserver.runtime")
public final class SqlServerRuntimeProperties {
    private final String serverName,instanceName,databaseName,username,password;
    private final Integer port;
    private final Boolean trustServerCertificate;

    @ConstructorBinding
    public SqlServerRuntimeProperties(String serverName,Integer port,String instanceName,
            String databaseName,String username,String password,Boolean trustServerCertificate) {
        if(!server(serverName) || port!=null && (port<1 || port>65535)
                || instanceName!=null && (!instanceName.matches("[A-Za-z0-9_$.-]+") || port!=null)
                || !text(databaseName,128) || !text(username,128) || password==null || password.isEmpty()) {
            throw new IllegalArgumentException("Invalid SQL Server runtime configuration.");
        }
        this.serverName=serverName;
        this.instanceName=instanceName;
        this.port=port==null && instanceName==null?Integer.valueOf(1433):port;
        this.databaseName=databaseName;
        this.username=username;
        this.password=password;
        this.trustServerCertificate=trustServerCertificate==null?Boolean.FALSE:trustServerCertificate;
    }

    private static boolean text(String value,int max) {
        return value!=null && !value.isBlank() && value.length()<=max
                && value.chars().noneMatch(Character::isISOControl);
    }
    private static boolean server(String value) {
        if(value==null || value.isBlank())return false;
        if(value.equals("(local)") || value.matches("[A-Za-z0-9_.-]+"))return true;
        String ip=value.startsWith("[") && value.endsWith("]")?value.substring(1,value.length()-1):value;
        return ip.chars().filter(c->c==':').count()>=2 && ip.matches("[0-9A-Fa-f:.]+");
    }

    public String serverName(){return serverName;}
    public Integer port(){return port;}
    public String instanceName(){return instanceName;}
    public String databaseName(){return databaseName;}
    public String username(){return username;}
    public String password(){return password;}
    public Boolean trustServerCertificate(){return trustServerCertificate;}
    @Override public String toString(){return "SqlServerRuntimeProperties[redacted]";}
}
