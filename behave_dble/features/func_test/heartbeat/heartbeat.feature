# Copyright (C) 2016-2019 ActionTech.
# License: https://www.mozilla.org/en-US/MPL/2.0 MPL version 2 or higher.
# Created by wujinling at 2019/11/27
Feature: heartbeat basic test
   @skip
   #now select @@lower_case_table_names,@@autocommit, @@tx_isolation,@@read_only also need one connection before heart recover, so skip this case first.
   Scenario:  heartbeat is not controlled by maxCon: when connections exceeded the maxCon, the heartbeat connection still can be created #1
    Given delete the following xml segment
      |file        | parent          | child               |
      |schema.xml  |{'tag':'root'}   | {'tag':'schema'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataNode'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataHost'}  |
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
     <schema  name="schema1" sqlMaxLimit="100">
         <table name="sharding_2_t1" dataNode="dn1,dn3" rule="hash-two" />
     </schema>

     <dataNode dataHost="ha_group1" database="db1" name="dn1" />
     <dataNode dataHost="ha_group1" database="db2" name="dn3" />

     <dataHost balance="0" maxCon="4" minCon="3" name="ha_group1" slaveThreshold="100" switchType="1">
        <heartbeat>select user()</heartbeat>
        <writeHost host="hostM1" password="111111" url="172.100.9.5:3306" user="test">
        </writeHost>
     </dataHost>
    """
    Given Restart dble in "dble-1" success
    Then execute sql in "dble-1" in "user" mode
     | user | passwd | conn   | toClose  | sql                         | expect  | db     |
     | test | 111111 | conn_0 | False    | drop table if exists sharding_2_t1   | success | schema1 |
     | test | 111111 | conn_0 | True     | create table sharding_2_t1(id int,name varchar(30))    | success | schema1 |
    Then get resultset of admin cmd "show @@backend" named "backend_rs_A"
    Given kill "heartbeat" connection from "backend_rs_A" in "mysql-master1" success
    Then execute sql in "dble-1" in "user" mode
     | user | passwd | conn   | toClose  | sql                         | expect  | db     |
     | test | 111111 | conn_1 | False    | begin   | success | schema1  |
     | test | 111111 | conn_1 | False    | select * from sharding_2_t1 | success | schema1 |
     | test | 111111 | conn_2 | False    | begin   | success | schema1  |
     | test | 111111 | conn_2 | False    | select * from sharding_2_t1 | success | schema1 |
    Given sleep "20" seconds
    Then get resultset of admin cmd "show @@backend" named "backend_rs_B"
    Then check resultset "backend_rs_B" has lines with following column values
      | HOST-3           | USED_FOR_HEARTBEAT-22  |
      |    172.100.9.5  | false       |
      |    172.100.9.5  | false       |
      |    172.100.9.5  | false       |
      |    172.100.9.5  | false       |
      |    172.100.9.5  | true        |
    Then execute sql in "dble-1" in "user" mode
     | user | passwd | conn   | toClose  | sql              | expect  | db     |
     | test | 111111 | conn_1 | True     | commit           | success | schema1  |
     | test | 111111 | conn_2 | True     | commit           | success | schema1  |


  Scenario: the killed heartbeat connection can recover in next heartbeat checking #2
    Given delete the following xml segment
      |file        | parent          | child               |
      |schema.xml  |{'tag':'root'}   | {'tag':'schema'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataNode'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataHost'}    |
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
    <schema  name="schema1" sqlMaxLimit="100">
         <table name="sharding_2_t1" dataNode="dn1,dn3" rule="hash-two" />
     </schema>

     <dataNode dataHost="ha_group1" database="db1" name="dn1" />
     <dataNode dataHost="ha_group1" database="db2" name="dn3" />

    <dataHost balance="0" maxCon="100" minCon="10" name="ha_group1" slaveThreshold="100" switchType="1">
        <heartbeat>select user()</heartbeat>
        <writeHost host="hostM1" password="111111" url="172.100.9.5:3306" user="test">
        </writeHost>
     </dataHost>
    """
    Given Restart dble in "dble-1" success
    Then get resultset of admin cmd "show @@backend" named "backend_rs_C"
    Given kill "heartbeat" connection from "backend_rs_C" in "mysql-master1" success
    Given sleep "12" seconds
    Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                               | expect                 | db  |
      | test | 111111 | new    | True    | select * from sharding_2_t1    | error totally whack  | schema1 |
    Given sleep "10" seconds
    Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                               | expect  | db  |
      | test | 111111 | new    | True    | select * from sharding_2_t1    | success | schema1 |

  Scenario: the heartbeat will retry 'errorRetryCount' times to recover the connection when the mysql service was stopped #3
    Given delete the following xml segment
      |file        | parent          | child               |
      |schema.xml  |{'tag':'root'}   | {'tag':'schema'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataNode'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataHost'}    |
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
     <schema  name="schema1" sqlMaxLimit="100">
         <table name="sharding_2_t1" dataNode="dn1,dn3" rule="hash-two" />
     </schema>

     <dataNode dataHost="ha_group1" database="db1" name="dn1" />
     <dataNode dataHost="ha_group1" database="db2" name="dn3" />

     <dataHost balance="0" maxCon="100" minCon="10" name="ha_group1" slaveThreshold="100" switchType="1">
        <heartbeat errorRetryCount="3">select user()</heartbeat>
        <writeHost host="hostM1" password="111111" url="172.100.9.5:3306" user="test">
        </writeHost>
     </dataHost>
    """
    Given Restart dble in "dble-1" success
    Given execute oscmd in "dble-1"
    """
    echo >/opt/dble/logs/dble.log
    """
    Given stop mysql in host "mysql-master1"
    Given sleep "12" seconds
    Then check following " " exist in file "/opt/dble/logs/dble.log" in "dble-1"
    """
    heartbeat failed, retry for the 1 times
    heartbeat failed, retry for the 2 times
    heartbeat failed, retry for the 3 times
    """
    Given start mysql in host "mysql-master1"
    Given sleep "20" seconds
    Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                               | expect  | db  |
      | test | 111111 | new    | True    | select * from sharding_2_t1    | success | schema1 |

  Scenario: set errorRetryCount> and timeout>0: after kill the heartbeat connections it will create a new one #4
   #1.record error msg in dble.log
   #2.in <timeout seconds the front connection work fine
   Given delete the following xml segment
      |file        | parent          | child               |
      |schema.xml  |{'tag':'root'}   | {'tag':'schema'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataNode'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataHost'}    |
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
     <schema  name="schema1" sqlMaxLimit="100">
         <table name="sharding_2_t1" dataNode="dn1,dn3" rule="hash-two" />
     </schema>

     <dataNode dataHost="ha_group1" database="db1" name="dn1" />
     <dataNode dataHost="ha_group1" database="db2" name="dn3" />

     <dataHost balance="0" maxCon="100" minCon="10" name="ha_group1" slaveThreshold="100" switchType="1">
        <heartbeat errorRetryCount="3" timeout ="20">select user()</heartbeat>
        <writeHost host="hostM1" password="111111" url="172.100.9.5:3306" user="test">
        </writeHost>
     </dataHost>
    """
   Given Restart dble in "dble-1" success
   Given execute oscmd in "dble-1"
    """
    echo >/opt/dble/logs/dble.log
    """
   Then get resultset of admin cmd "show @@backend" named "backend_rs_E"
   Given kill "heartbeat" connection from "backend_rs_E" in "mysql-master1" success
   Given sleep "12" seconds
   Then check following " " exist in file "/opt/dble/logs/dble.log" in "dble-1"
    """
    heartbeat setError
    """
   Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                               | expect  | db  |
      | test | 111111 | new    | True    | select * from sharding_2_t1    | success | schema1 |
   Then get resultset of admin cmd "show @@backend" named "backend_rs_F"
   Then check resultset "backend_rs_F" has lines with following column values
      | HOST-3           | USED_FOR_HEARTBEAT-22  |
      |    172.100.9.5  | true                      |

 @skip
 @btrace
 Scenario: set errorRetryCount> and timeout>0: heartbeat connection not return yet #5
   #1.in <timeout seconds,the client work fine
   #2.in >timeout seconds,the client return error and record time out value in dble.log
#   Given delete the following xml segment
#      |file        | parent          | child               |
#      |schema.xml  |{'tag':'root'}   | {'tag':'dataHost'}    |
#    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
#    """
#     <dataHost balance="0" maxCon="100" minCon="10" name="172.100.9.5" slaveThreshold="100" switchType="1">
#        <heartbeat errorRetryCount="3" timeout ="10">select user()</heartbeat>
#        <writeHost host="hostM1" password="111111" url="172.100.9.5:3306" user="test">
#        </writeHost>
#     </dataHost>
#    """
#   Given add xml segment to node with attribute "{'tag':'system'}" in "server.xml"
#    """
#        <property name="dataNodeHeartbeatPeriod">20000</property>
#    """
    Given delete the following xml segment
      |file        | parent          | child               |
      |schema.xml  |{'tag':'root'}   | {'tag':'schema'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataNode'}    |
      |schema.xml  |{'tag':'root'}   | {'tag':'dataHost'}    |
    Given add xml segment to node with attribute "{'tag':'root'}" in "schema.xml"
    """
     <schema  name="schema1" sqlMaxLimit="100">
         <table name="sharding_2_t1" dataNode="dn1,dn3" rule="hash-two" />
     </schema>

     <dataNode dataHost="ha_group1" database="db1" name="dn1" />
     <dataNode dataHost="ha_group1" database="db2" name="dn3" />

     <dataHost balance="0" maxCon="100" minCon="10" name="ha_group1" slaveThreshold="100" switchType="1">
        <heartbeat errorRetryCount="3" timeout ="20">select user()</heartbeat>
        <writeHost host="hostM1" password="111111" url="172.100.9.5:3306" user="test">
        </writeHost>
     </dataHost>
    """
   Given Restart dble in "dble-1" success
   Given prepare a thread run btrace script "BtraceHeartbeat.java" in "dble-1"
   Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                               | expect  | db  |
      | test | 111111 | conn_1    | False    | select * from sharding_2_t1    | success | schema1 |
   Then get resultset of admin cmd "show @@backend" named "backend_rs_G"
   Given kill "heartbeat" connection from "backend_rs_G" in "mysql-master1" success
   Given sleep "13" seconds
   Then execute sql in "dble-1" in "user" mode
      | user | passwd | conn   | toClose | sql                                  | expect  | db  |
      | test | 111111 | conn_1    | True    | select * from sharding_2_t1    | the data source[172.100.9.5:3306] can't reached | schema1 |
#      | test | 111111 | conn_1    | True    | select * from sharding_2_t1    | success | schema1 |
   Then check following " " exist in file "/opt/dble/logs/dble.log" in "dble-1"
    """
    heartbeat setTimeout
    """
   Given stop btrace script "BtraceHeartbeat.java" in "dble-1"
   Given destroy btrace threads list

