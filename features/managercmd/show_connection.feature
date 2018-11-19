# Created by maofei at 2018/11/6
Feature:
  Scenario: # show @@connection.sql
    # 1 the execute time of query <1ms
    # 2 the execute time of query >1ms
    # 3 multiple session query display
    # 4 multiple select executed query
    Given delete the following xml segment
      |file         | parent           | child                 |
      |schema.xml  |{'tag':'root'}   | {'tag':'schema'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataNode'}  |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataHost'}  |
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
        <schema dataNode="dn1" name="mytest" sqlMaxLimit="100">
		    <table dataNode="dn1,dn2,dn3,dn4" name="test" type="global" />
	    </schema>
	    <dataNode dataHost="172.100.9.1" database="db1" name="dn1" />
	    <dataNode dataHost="172.100.9.1" database="db2" name="dn2" />
	    <dataNode dataHost="172.100.9.1" database="db3" name="dn3" />
	    <dataNode dataHost="172.100.9.1" database="db4" name="dn4" />
	    <dataHost balance="0" maxCon="9" minCon="3" name="172.100.9.1" switchType="1">
		    <heartbeat>select user()</heartbeat>
		    <writeHost host="hostM1" password="111111" url="172.100.9.1:3306" user="test">
		    </writeHost>
	    </dataHost>
    """
    Given Restart dble in "dble-1" success
    Then execute admin cmd "create database @@dataNode ='dn1,dn2,dn3,dn4'"
    #1
    Then execute sql in "dble-1" in "user" mode
      | user  | passwd    | conn   | toClose | sql                      | expect  | db       |
      | test  | 111111    | conn_0 | False   | select sleep(0.0001)   | success | mytest  |
    Then get resultset of admin cmd "show @@connection.sql" named "conn_rs_A"
    Then check resultset "conn_rs_A" has lines with following column values
      | EXECUTE_TIME-5 | SQL-6                  |
      |    0+200         | select sleep(0.0001) |
    Given sleep "2" seconds
    Then get resultset of admin cmd "show @@connection.sql" named "conn_rs_B"
    Then check resultset "conn_rs_B" has lines with following column values
      | EXECUTE_TIME-5 | SQL-6                  |
      |    0+200         | select sleep(0.0001) |
    #2
    Then execute sql in "dble-1" in "user" mode
      | user  | passwd    | conn   | toClose  | sql                      | expect  | db       |
      | test  | 111111    | conn_0 | False    | select sleep(0.1)      | success | mytest   |
    Then get resultset of admin cmd "show @@connection.sql" named "conn_rs_C"
    Then check resultset "conn_rs_C" has lines with following column values
      | EXECUTE_TIME-5 | SQL-6                  |
      |    100+200      | select sleep(0.1)    |
    Given sleep "2" seconds
    Then get resultset of admin cmd "show @@connection.sql" named "conn_rs_D"
    Then check resultset "conn_rs_D" has lines with following column values
      | EXECUTE_TIME-5 | SQL-6                  |
      |    100+200      | select sleep(0.1)    |
    #3
    Then execute sql in "dble-1" in "user" mode
      | user  | passwd    | conn   | toClose  | sql                      | expect  | db       |
      | test  | 111111    | conn_1 | False    | select sleep(1)        | success | mytest   |
    Then get resultset of admin cmd "show @@connection.sql" named "conn_rs_E"
    Then check resultset "conn_rs_E" has lines with following column values
      | EXECUTE_TIME-5 | SQL-6                 |
      |    100+200      | select sleep(0.1)    |
      |    1000+200     | select sleep(1)      |





