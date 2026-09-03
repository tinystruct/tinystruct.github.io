# Tinystruct 鏁版嵁搴撻泦鎴?
鏈寚鍗椾互 [bible-online](https://github.com/m0ver/bible-online) 椤圭洰涓哄弬鑰冿紝浠嬬粛濡備綍鍦?Tinystruct 搴旂敤绋嬪簭涓泦鎴愬拰浣跨敤鏁版嵁搴撱€?
## 鏀寔鐨勬暟鎹簱

Tinystruct 鍐呯疆鏀寔浠ヤ笅鏁版嵁搴撶郴缁燂細

- SQLite
- MySQL
- H2
- Microsoft SQL Server
- Redis

## 閰嶇疆

### 鏁版嵁搴撳睘鎬?
鍦?`application.properties` 涓厤缃暟鎹簱杩炴帴锛?
```properties
# SQLite 閰嶇疆锛坆ible-online 瀹為檯浣跨敤锛?driver=org.sqlite.JDBC
database.url=jdbc:sqlite:src/main/resources/bible.db
database.user=
database.password=
database.connections.max=1

# MySQL 閰嶇疆
# driver=com.mysql.cj.jdbc.Driver
# database.url=jdbc:mysql://localhost:3306/mydb?useSSL=false&serverTimezone=UTC
# database.user=root
# database.password=password
# database.connections.max=10

# H2 閰嶇疆
# driver=org.h2.Driver
# database.url=jdbc:h2:~/test
# database.user=sa
# database.password=
# database.connections.max=10
```

> **鎻愮ず锛?* 宓屽叆寮?SQLite 浣跨敤 `database.connections.max=1` 鍗冲彲锛汳ySQL 绛夊叡浜湇鍔″櫒寤鸿璁剧疆涓?`10` 鎴栨洿楂樸€?
涔熷彲閫氳繃閰嶇疆鑺傚ご瀹氫箟鍛藉悕鏁版嵁搴撻厤缃細

```properties
[database]
driver=com.mysql.cj.jdbc.Driver
database.url=jdbc:mysql://localhost:3306/mydb
database.user=root
database.password=secret
database.connections.max=10
```

---

## 鏁版嵁搴撹闂柟寮?
Tinystruct 鎻愪緵涓ょ浜掕ˉ鐨勬暟鎹簱璁块棶鏂瑰紡锛?
1. **瀵硅薄鏄犲皠锛坄AbstractData`锛?* 鈥?鎺ㄨ崘鏂瑰紡銆傚畾涔夋ā鍨嬬被鍜?XML 鏄犲皠鏂囦欢锛岃皟鐢ㄥ唴缃?CRUD 鏂规硶銆?2. **`DatabaseOperator`** 鈥?搴曞眰宸ュ叿锛岄€傜敤浜庡師濮?SQL銆佽仛鍚堟煡璇㈡垨璺ㄨ〃鎿嶄綔銆?
---

## 瀵硅薄鏄犲皠鏂瑰紡

杩欐槸鍦?Tinystruct 涓搷浣滄暟鎹簱瀹炰綋鐨?*鎺ㄨ崘鏂瑰紡**銆傚皢 Java POJO 涓?XML 鏄犲皠鏂囦欢缁撳悎锛屾彁渚涢€忔槑鐨?CRUD 鎿嶄綔銆?
### 1. 瀹氫箟妯″瀷绫?
妯″瀷绫荤户鎵?`AbstractData`锛屽苟鍦ㄦ瘡涓?setter 涓娇鐢?`setFieldAs*` 杈呭姪鏂规硶銆傝繖浜涙柟娉曡礋璐ｅ皢瀛楁娉ㄥ唽鍒?ORM锛屼娇 `append()`銆乣update()` 鍜?`delete()` 鐭ラ亾鍝簺瀛楁闇€瑕佹寔涔呭寲銆?
```java
package custom.objects;

import java.util.Date;
import org.tinystruct.data.component.AbstractData;
import org.tinystruct.data.component.Row;

public class User extends AbstractData {
    private String email;
    private String username;
    private String password;
    private String nickname;
    private int gender;
    private String firstName;
    private String lastName;
    private String country;
    private String city;
    private Date lastloginTime;
    private Date registrationTime;
    private boolean status;

    // 杩斿洖鑷姩鐢熸垚鐨?UUID 瀛楃涓?    public String getId() {
        return String.valueOf(this.Id);
    }

    // setter 蹇呴』璋冪敤 setFieldAs* 灏嗗€兼敞鍐屽埌 ORM
    public void setEmail(String email) {
        this.email = this.setFieldAsString("email", email);
    }
    public String getEmail() { return this.email; }

    public void setUsername(String username) {
        this.username = this.setFieldAsString("username", username);
    }
    public String getUsername() { return this.username; }

    public void setPassword(String password) {
        this.password = this.setFieldAsString("password", password);
    }
    public String getPassword() { return this.password; }

    public void setNickname(String nickname) {
        this.nickname = this.setFieldAsString("nickname", nickname);
    }
    public String getNickname() { return this.nickname; }

    public void setGender(int gender) {
        this.gender = this.setFieldAsInt("gender", gender);
    }
    public int getGender() { return this.gender; }

    public void setFirstName(String firstName) {
        this.firstName = this.setFieldAsString("firstName", firstName);
    }
    public String getFirstName() { return this.firstName; }

    public void setLastName(String lastName) {
        this.lastName = this.setFieldAsString("lastName", lastName);
    }
    public String getLastName() { return this.lastName; }

    public void setCountry(String country) {
        this.country = this.setFieldAsString("country", country);
    }
    public String getCountry() { return this.country; }

    public void setCity(String city) {
        this.city = this.setFieldAsString("city", city);
    }
    public String getCity() { return this.city; }

    public void setLastloginTime(Date lastloginTime) {
        this.lastloginTime = this.setFieldAsDate("lastloginTime", lastloginTime);
    }
    public Date getLastloginTime() { return this.lastloginTime; }

    public void setRegistrationTime(Date registrationTime) {
        this.registrationTime = this.setFieldAsDate("registrationTime", registrationTime);
    }
    public Date getRegistrationTime() { return this.registrationTime; }

    public void setStatus(boolean status) {
        this.status = this.setFieldAsBoolean("status", status);
    }
    public boolean getStatus() { return this.status; }

    // setData() 灏嗘暟鎹簱鍒楀悕锛坰nake_case锛夋槧灏勫埌 Java 瀛楁
    @Override
    public void setData(Row row) {
        if (row.getFieldInfo("id") != null)
            this.setId(row.getFieldInfo("id").stringValue());
        if (row.getFieldInfo("email") != null)
            this.setEmail(row.getFieldInfo("email").stringValue());
        if (row.getFieldInfo("username") != null)
            this.setUsername(row.getFieldInfo("username").stringValue());
        if (row.getFieldInfo("password") != null)
            this.setPassword(row.getFieldInfo("password").stringValue());
        if (row.getFieldInfo("nickname") != null)
            this.setNickname(row.getFieldInfo("nickname").stringValue());
        if (row.getFieldInfo("gender") != null)
            this.setGender(row.getFieldInfo("gender").intValue());
        if (row.getFieldInfo("first_name") != null)
            this.setFirstName(row.getFieldInfo("first_name").stringValue());
        if (row.getFieldInfo("last_name") != null)
            this.setLastName(row.getFieldInfo("last_name").stringValue());
        if (row.getFieldInfo("country") != null)
            this.setCountry(row.getFieldInfo("country").stringValue());
        if (row.getFieldInfo("city") != null)
            this.setCity(row.getFieldInfo("city").stringValue());
        if (row.getFieldInfo("lastlogin_time") != null)
            this.setLastloginTime(row.getFieldInfo("lastlogin_time").dateValue());
        if (row.getFieldInfo("registration_time") != null)
            this.setRegistrationTime(row.getFieldInfo("registration_time").dateValue());
        if (row.getFieldInfo("status") != null)
            this.setStatus(row.getFieldInfo("status").booleanValue());
    }

    @Override
    public String toString() {
        StringBuffer buffer = new StringBuffer();
        buffer.append("{");
        buffer.append("\"Id\":\"" + this.getId() + "\"");
        buffer.append(",\"email\":\"" + this.getEmail() + "\"");
        buffer.append(",\"username\":\"" + this.getUsername() + "\"");
        buffer.append(",\"nickname\":\"" + this.getNickname() + "\"");
        buffer.append(",\"gender\":" + this.getGender());
        buffer.append(",\"firstName\":\"" + this.getFirstName() + "\"");
        buffer.append(",\"lastName\":\"" + this.getLastName() + "\"");
        buffer.append(",\"country\":\"" + this.getCountry() + "\"");
        buffer.append(",\"city\":\"" + this.getCity() + "\"");
        buffer.append(",\"lastloginTime\":\"" + this.getLastloginTime() + "\"");
        buffer.append(",\"registrationTime\":\"" + this.getRegistrationTime() + "\"");
        buffer.append(",\"status\":" + this.getStatus());
        buffer.append("}");
        return buffer.toString();
    }
}
```

#### 鍙敤鐨?`setFieldAs*` 鏂规硶

| 鏂规硶 | Java 绫诲瀷 | XML `type` |
|---|---|---|
| `setFieldAsString(name, value)` | `String` | `varchar`銆乣longtext` |
| `setFieldAsInt(name, value)` | `int` | `int` |
| `setFieldAsDate(name, value)` | `java.util.Date` | `datetime` |
| `setFieldAsBoolean(name, value)` | `boolean` | `bit` |
| `setFieldAsLocalDateTime(name, value)` | `LocalDateTime` | `DATETIME` |

### 2. 鍒涘缓 XML 鏄犲皠鏂囦欢

灏嗘槧灏勬枃浠舵斁鍦?`src/main/resources` 涓嬶紝璺緞涓?Java 鍖呰矾寰勪竴鑷淬€備緥濡?`custom.objects.User` 绫诲搴旓細

```
src/main/resources/custom/objects/User.map.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>

<mapping>
 <class name="User" table="User">
  <id name="Id" column="id" increment="false" generate="true" length="50" type="varchar"/>
  <property name="email"            column="email"             length="50"  type="varchar"/>
  <property name="username"         column="username"          length="50"  type="varchar"/>
  <property name="password"         column="password"          length="15"  type="varchar"/>
  <property name="nickname"         column="nickname"          length="50"  type="varchar"/>
  <property name="gender"           column="gender"            length="4"   type="int"/>
  <property name="firstName"        column="first_name"        length="10"  type="varchar"/>
  <property name="lastName"         column="last_name"         length="10"  type="varchar"/>
  <property name="country"          column="country"           length="50"  type="varchar"/>
  <property name="city"             column="city"              length="50"  type="varchar"/>
  <property name="lastloginTime"    column="lastlogin_time"    length="0"   type="datetime"/>
  <property name="registrationTime" column="registration_time" length="0"   type="datetime"/>
  <property name="status"           column="status"            length="1"   type="bit"/>
 </class>
</mapping>
```

#### XML 鏄犲皠鍏抽敭灞炴€?
| 灞炴€?| 鍚箟 |
|---|---|
| `<class>` 鐨?`name` | 绠€鍗曠被鍚嶏紙鏃犲寘鍓嶇紑锛?|
| `table` | 鏁版嵁搴撹〃鍚?|
| `<property>` 鐨?`name` | Java 灞炴€у悕锛坈amelCase锛?|
| `column` | 鏁版嵁搴撳垪鍚嶏紙閫氬父涓?snake_case锛?|
| `type` | SQL 鍒楃被鍨嬶紙`varchar`銆乣int`銆乣datetime`銆乣bit`銆乣longtext` 绛夛級 |
| `length` | 鍒楅暱搴︼紱`datetime`銆乣longtext` 绛夊彲鍙橀暱绫诲瀷濉?`0` |
| `<id>` 鐨?`increment="false"` | ID 涓嶆槸鏁板€煎瀷鑷 |
| `<id>` 鐨?`generate="true"` | 璋冪敤 `append()` 鏃舵鏋惰嚜鍔ㄧ敓鎴?UUID |

> **UUID 涓婚敭**锛歜ible-online 鎵€鏈夊疄浣撳潎浣跨敤 `generate="true"` + `type="varchar"` 浣滀负涓婚敭銆傝皟鐢?`append()` 鍓嶆棤闇€鎵嬪姩璁剧疆 ID鈥斺€旀鏋惰嚜鍔ㄧ敓鎴?UUID锛屼箣鍚庡彲閫氳繃 `getId()` 璇诲彇銆?
浠ヤ笅鏄」鐩腑鏇寸畝鍗曠殑鏄犲皠绀轰緥锛?
**`bible.map.xml`**锛堢粡鏂囪〃锛夛細
```xml
<?xml version="1.0" encoding="UTF-8"?>

<mapping>
 <class name="bible" table="bible">
  <id name="Id" column="id" increment="false" generate="true" length="48" type="varchar"/>
  <property name="bookId"    column="book_id"    length="4" type="int"/>
  <property name="chapterId" column="chapter_id" length="4" type="int"/>
  <property name="partId"    column="part_id"    length="4" type="int"/>
  <property name="content"   column="content"    length="0" type="longtext"/>
 </class>
</mapping>
```

**`book.map.xml`**锛?```xml
<?xml version="1.0" encoding="UTF-8"?>

<mapping>
 <class name="book" table="book">
  <id name="Id" column="id" increment="false" generate="true" length="50" type="varchar"/>
  <property name="bookId"   column="book_id"   length="4"   type="int"/>
  <property name="bookName" column="book_name" length="255" type="varchar"/>
  <property name="language" column="language"  length="10"  type="varchar"/>
 </class>
</mapping>
```

### 3. CRUD 鎿嶄綔

#### 鏂板 鈥?`append()`

```java
// 娉ㄥ唽鏂扮敤鎴凤紝UUID 鑷姩鐢熸垚
User user = new User();
user.setNickname(request.getParameter("nickname"));
user.setEmail(request.getParameter("email"));
user.setPassword(new Security(user.getEmail())
        .encodePassword(request.getParameter("password")));
user.setFirstName(request.getParameter("first-name"));
user.setLastName(request.getParameter("last-name"));
user.setGender(Integer.parseInt(request.getParameter("gender")));
user.setCountry(request.getParameter("country"));
user.setCity(request.getParameter("city"));
user.setLastloginTime(new Date());
user.setRegistrationTime(new Date());
user.append();  // INSERT锛泆ser.getId() 杩斿洖鏂扮敓鎴愮殑 UUID
```

#### 鏌ヨ 鈥?`findOneById()`

```java
User user = new User();
user.setId(someId);   // 浼犲叆 UUID 瀛楃涓?user.findOneById();   // SELECT ... WHERE id = ?
System.out.println(user.getEmail());
```

#### 鏉′欢鏌ヨ 鈥?`findWith()`

`findWith` 鏄?Tinystruct 鐨勪富瑕佹煡璇㈡柟娉曘€傛帴鍙楀弬鏁板寲鐨?WHERE/ORDER BY 瀛愬彞鍜屽€兼暟缁勶紝杩斿洖 `Table`锛坄Row` 瀵硅薄鐨勫垪琛級銆?
```java
// 鎸夌敤鎴峰悕鏌ユ壘
User u = new User();
Table list = u.findWith("WHERE username=? AND status='1'",
        new Object[]{"james"});

if (list.size() > 0) {
    u.setData(list.get(0));  // 鐢ㄧ涓€琛屾暟鎹～鍏呭璞?}
```

```java
// 鎸夎瑷€鏌ユ壘涔︾洰
book b = new book();
Table table = b.findWith("WHERE book_id=? AND language=?",
        new Object[]{bookId, "zh_CN"});

if (!table.isEmpty()) {
    b.setData(table.get(0));
}
```

#### 鏌ヨ鍏ㄩ儴 鈥?`findAll()`

```java
book b = new book();
Table list = b.findAll();

Iterator<Row> iter = list.iterator();
while (iter.hasNext()) {
    b.setData(iter.next());
    System.out.println(b.getBookName() + " (" + b.getLanguage() + ")");
}
```

#### 鑱氬悎鏌ヨ 鈥?`setRequestFields()`

璋冪敤 `findWith()` 鍓嶄娇鐢?`setRequestFields()` 瑕嗙洊 SELECT 鎶曞奖銆俠ible-online 閫氳繃姝ゆ柟寮忔鏌ラ偖绠辨槸鍚﹂噸澶嶅強鑾峰彇鏈€澶х珷鑺傛暟锛?
```java
// 娉ㄥ唽鍓嶆鏌ラ偖绠辨槸鍚﹀凡瀛樺湪
int count = user
    .setRequestFields("count(*) as p")
    .findWith("WHERE email=?", new Object[]{email})
    .get(0).getFieldInfo("p").intValue();

if (count > 0) {
    throw new ApplicationException("閭宸茶娉ㄥ唽銆?);
}
```

```java
// 鑾峰彇鏌愪功鐨勬渶澶х珷鑺傜紪鍙?bible bible = new bible();
int maxChapter = bible
    .setRequestFields("max(chapter_id) as max_chapter")
    .findWith("WHERE book_id=?", new Object[]{bookId})
    .get(0).get(0).get("max_chapter").intValue();
```

#### 鍔ㄦ€佸垏鎹㈣〃 鈥?`setTableName()`

褰撳悓涓€妯″瀷绫诲搴斿寮犵粨鏋勭浉鍚岀殑琛紙濡備笉鍚岀増鏈殑鍦ｇ粡璇戞枃琛級锛屽湪杩愯鏃惰皟鐢?`setTableName()` 鍒囨崲鐩爣琛細

```java
bible bible = new bible();
bible.setTableName("zh_CN");   // 榛樿锛氱畝浣撲腑鏂?
if (request.getParameter("version") != null) {
    switch (request.getParameter("version")) {
        case "NIV": bible.setTableName("NIV"); break;
        case "ESV": bible.setTableName("ESV"); break;
        case "KJV": bible.setTableName("KJV"); break;
    }
}

// 鏌ヨ鎵€閫夌増鏈殑缁忔枃
Table verses = bible
    .setRequestFields("*")
    .findWith("WHERE book_id=? AND chapter_id=? ORDER BY part_id",
              new Object[]{bookId, chapterId});
```

姝ゆā寮忎娇鎮ㄥ彲浠ョ淮鎶ゅ寮犵嫭绔嬭瘧鏂囪〃锛坄NIV`銆乣ESV`銆乣KJV`銆乣zh_CN`銆乣zh_TW` 绛夛級锛屽悓鏃跺叡鐢ㄤ竴涓ā鍨嬬被鍜屾槧灏勬枃浠躲€?
#### 鏇存柊 鈥?`update()`

```java
// 鐧诲綍鎴愬姛鍚庢洿鏂扮櫥褰曟椂闂?user.setLastloginTime(new Date());
user.update();   // UPDATE ... WHERE id = ?
```

#### 鍒犻櫎 鈥?`delete()`

```java
user.delete();   // DELETE FROM ... WHERE id = ?
```

#### 瀛樺湪鍒欐洿鏂般€佷笉瀛樺湪鍒欐柊澧炴ā寮?
bible-online 涓父瑙佺殑鍋氭硶鏄厛鏌ヨ璁板綍鏄惁瀛樺湪锛屽啀鍐冲畾鎻掑叆杩樻槸鏇存柊锛?
```java
// 鏇存柊鎴栨柊澧炵櫥褰曟棩蹇?Log log = new Log();
Table logs = log.findWith("WHERE user_id=?",
        new Object[]{currentUser.getId()});

if (!logs.isEmpty()) {
    log.setData(logs.get(0));
    log.setDate(new Date());
    log.update();              // 璁板綍瀛樺湪锛屾洿鏂板畠
} else {
    log.setUserId(currentUser.getId());
    log.setAction("鐧诲綍鎴愬姛");
    log.setActionType(0);
    log.setDate(new Date());
    log.append();              // 灏氭棤璁板綍锛屾彃鍏ュ畠
}
```

### 4. `Table` 涓?`Row` API

`findWith()` 鍜?`findAll()` 杩斿洖 `Table`锛坄Row` 瀵硅薄鐨勬湁搴忓垪琛級銆俙Row` 鏄垪鍚嶅埌 `Field` 鍊肩殑鏄犲皠銆?
```java
Table table = bible.findWith(
    "WHERE book_id=? AND chapter_id=? ORDER BY part_id",
    new Object[]{bookId, chapterId});

for (int i = 0; i < table.size(); i++) {
    Row row = table.get(i);
    bible.setData(row);            // 鐢ㄨ琛屾暟鎹～鍏呮ā鍨?    System.out.println(bible.getContent());
}
```

涔熷彲浠ョ洿鎺ヤ粠 `Row` 璇诲彇 `Field` 鍊硷紝鏃犻渶濉厖妯″瀷瀵硅薄锛?
```java
Row row = table.get(0);
int     maxChapter = row.getFieldInfo("max_chapter").intValue();
String  email      = row.getFieldInfo("email").stringValue();
Date    created    = row.getFieldInfo("registration_time").dateValue();
boolean active     = row.getFieldInfo("status").booleanValue();
```

### 5. 澶氬疄浣撳崗浣滅ず渚嬶紙鐢ㄦ埛娉ㄥ唽锛?
浠ヤ笅绀轰緥鏉ヨ嚜 bible-online 鐨?`register` 搴旂敤锛屽睍绀哄涓?`AbstractData` 瀵硅薄濡備綍鍦ㄥ悓涓€娴佺▼涓崗浣滐細

```java
public boolean append(Request request) throws ApplicationException {
    // 1. 鏍规嵁璇锋眰鍙傛暟鏋勫缓 User 瀵硅薄
    User user = new User();
    user.setNickname(request.getParameter("nickname"));
    user.setEmail(request.getParameter("email"));
    user.setPassword(new Security(user.getEmail())
            .encodePassword(request.getParameter("password")));
    user.setFirstName(request.getParameter("first-name"));
    user.setLastName(request.getParameter("last-name"));
    user.setGender(Integer.parseInt(request.getParameter("gender")));
    user.setCountry(request.getParameter("country"));
    user.setCity(request.getParameter("city"));
    user.setLastloginTime(new Date());
    user.setRegistrationTime(new Date());

    // 2. 闃叉閲嶅娉ㄥ唽
    int count = user
        .setRequestFields("count(*) as p")
        .findWith("WHERE email=?", new Object[]{user.getEmail()})
        .get(0).getFieldInfo("p").intValue();

    if (count > 0) {
        throw new ApplicationException("閭宸茶娉ㄥ唽銆?);
    }

    // 3. 鎻掑叆鐢ㄦ埛璁板綍锛圲UID 鑷姩鐢熸垚锛?    user.append();

    // 4. 灏嗘柊鐢ㄦ埛鍔犲叆榛樿鎴愬憳缁?    Member member = new Member();
    member.setUserId(user.getId());  // user.getId() 杩斿洖鏂扮敓鎴愮殑 UUID
    member.setGroupId("386e27c2-5db6-4f63-b28d-68a4adec2fd6");
    member.append();

    return true;
}
```

---

## 鍐呭瓨缂撳瓨 鈥?`Cache`

瀵逛簬璇婚鐜囬珮銆佸彉鍖栬緝灏戠殑鏁版嵁锛堝涔︾洰鍏冩暟鎹€佺珷鑺傛暟閲忥級锛宐ible-online 浣跨敤 Tinystruct 鍐呯疆鐨?`Cache` 鍗曚緥閬垮厤閲嶅鏌ヨ鏁版嵁搴擄細

```java
private static final Cache data = Cache.getInstance();

// 浼樺厛浠庣紦瀛樿鍙?String cacheKey = "book:" + bookId + ":lang:" + lang;
book book;

if (data.get(cacheKey) != null) {
    book = (book) data.get(cacheKey);
} else {
    book = new book();
    Table table = book.findWith("WHERE book_id=? AND language=?",
            new Object[]{bookId, lang});
    if (!table.isEmpty()) {
        book.setData(table.get(0));
    }
    data.set(cacheKey, book);  // 鍐欏叆缂撳瓨渚涘悗缁姹備娇鐢?}
```

鑱氬悎缁撴灉鍚屾牱閫傜敤姝ゆā寮忥細

```java
String maxChapterKey = "book:" + bookId + ":max_chapter";
int maxChapter;

if (data.get(maxChapterKey) != null) {
    maxChapter = (int) data.get(maxChapterKey);
} else {
    maxChapter = bible
        .setRequestFields("max(chapter_id) as max_chapter")
        .findWith("WHERE book_id=?", new Object[]{bookId})
        .get(0).get(0).get("max_chapter").intValue();
    data.set(maxChapterKey, maxChapter);
}
```

閫傚悎浣跨敤 `Cache` 鐨勬暟鎹壒寰侊細
- 璇诲彇闈炲父棰戠箒
- 鍦ㄨ繘绋嬬敓鍛藉懆鏈熷唴鍩烘湰涓嶅彉
- 鏁版嵁閲忓皬锛岄€傚悎鏀惧湪鍫嗗唴瀛樹腑

---

## DatabaseOperator

瀵逛簬鍘熷 SQL銆佸琛ㄨ繛鎺ワ紝鎴栧璞℃槧灏?API 鏃犳硶瑕嗙洊鐨勬搷浣滐紝浣跨敤 `DatabaseOperator`銆?
### 鍒涘缓 DatabaseOperator

```java
// 榛樿鈥斺€斾粠杩炴帴姹犲€熺敤涓€涓繛鎺?DatabaseOperator operator = new DatabaseOperator();

// 鍛藉悕閰嶇疆锛堝搴?application.properties 涓殑 [鑺俔 鍚嶏級
DatabaseOperator operator = new DatabaseOperator("myDatabase");

// 浣跨敤鐜版湁杩炴帴
DatabaseOperator operator = new DatabaseOperator(connection);
```

### 鎵ц鏌ヨ

```java
// 鍙傛暟鍖栨煡璇紙濮嬬粓浼樹簬瀛楃涓叉嫾鎺ワ級
PreparedStatement stmt = operator.preparedStatement(
    "SELECT id, username, email FROM User WHERE id = ?",
    new Object[]{userId}
);
ResultSet results = operator.executeQuery(stmt);

while (results.next()) {
    String email = results.getString("email");
}
```

### 鎵ц鏇存柊

```java
PreparedStatement stmt = operator.preparedStatement(
    "INSERT INTO User (username, email) VALUES (?, ?)",
    new Object[]{"james", "james@example.com"}
);
int rowsAffected = operator.executeUpdate(stmt);
```

### 璧勬簮绠＄悊

浣跨敤 try-with-resources 纭繚杩炴帴褰掕繕杩炴帴姹狅細

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    ResultSet results = operator.query("SELECT * FROM User");
    // 澶勭悊缁撴灉
} // 鑷姩鍏抽棴 ResultSet銆丳reparedStatement 骞堕噴鏀捐繛鎺?```

### SQL 娉ㄥ叆淇濇姢

`DatabaseOperator` 榛樿妫€娴?SQL 娉ㄥ叆銆備粎鍦ㄥ彲淇″唴閮ㄥ伐鍏蜂腑绂佺敤锛?
```java
operator.disableSafeCheck();
```

### 浜嬪姟

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    operator.beginTransaction();
    try {
        PreparedStatement s1 = operator.preparedStatement(
            "UPDATE accounts SET balance = balance - ? WHERE id = ?",
            new Object[]{amount, fromId}
        );
        operator.executeUpdate(s1);

        PreparedStatement s2 = operator.preparedStatement(
            "UPDATE accounts SET balance = balance + ? WHERE id = ?",
            new Object[]{amount, toId}
        );
        operator.executeUpdate(s2);

        operator.commitTransaction();
    } catch (Exception e) {
        operator.rollbackTransaction();
        throw e;
    }
}
```

#### 浜嬪姟鏂规硶

| 鏂规硶 | 璇存槑 |
|---|---|
| `beginTransaction()` | 寮€濮嬫柊浜嬪姟 |
| `commitTransaction()` | 鎻愪氦褰撳墠浜嬪姟 |
| `rollbackTransaction()` | 鍥炴粴鏁翠釜浜嬪姟 |
| `rollbackTransaction(Savepoint)` | 鍥炴粴鍒版寚瀹氫繚瀛樼偣 |
| `createSavepoint(String)` | 鍒涘缓鍛藉悕淇濆瓨鐐?|
| `releaseSavepoint(Savepoint)` | 閲婃斁淇濆瓨鐐?|
| `isInTransaction()` | 杩斿洖浜嬪姟鏄惁澶勪簬娲诲姩鐘舵€?|

> 鑻?`DatabaseOperator` 鍦ㄤ簨鍔℃湭鎻愪氦鎴栧洖婊氱殑鎯呭喌涓嬭鍏抽棴锛屼簨鍔″皢**鑷姩鍥炴粴**浠ヤ繚鎶ゆ暟鎹畬鏁存€с€?
---

## 鍐呯疆 POJO 鐢熸垚鍣?
Tinystruct 鍐呯疆浠ｇ爜鐢熸垚鍣紝鍙洿鎺ヤ粠鏁版嵁搴撴ā寮忕敓鎴愭ā鍨嬬被鍜?XML 鏄犲皠鏂囦欢銆傛敮鎸?**MySQL**銆?*MSSQL**銆?*SQLite** 鍜?**H2**銆?
### 杩愯鐢熸垚鍣?
```bash
# 浜や簰妯″紡鈥斺€旀彁绀鸿緭鍏ヨ〃鍚嶅拰杈撳嚭璺緞
bin/dispatcher generate

# 闈炰氦浜掓ā寮忊€斺€旀寚瀹氬崟寮犺〃
bin/dispatcher generate --tables users

# 澶氬紶琛紙鍒嗗彿鍒嗛殧锛?bin/dispatcher generate --tables "users;orders;products"
```

### 鑷姩绫诲瀷鏄犲皠

| SQL 鍒楃被鍨?| Java 绫诲瀷 | `setFieldAs*` 鏂规硶 |
|---|---|---|
| `VARCHAR`銆乣CHAR`銆乣TEXT` | `String` | `setFieldAsString` |
| `INT`銆乣SMALLINT`銆乣TINYINT` | `int` | `setFieldAsInt` |
| `BIGINT` | `long` | *锛堝師濮嬪瓧娈碉級* |
| `FLOAT` | `float` | *锛堝師濮嬪瓧娈碉級* |
| `DOUBLE` | `double` | *锛堝師濮嬪瓧娈碉級* |
| `DATETIME`銆乣TIMESTAMP` | `LocalDateTime` | `setFieldAsLocalDateTime` |
| `DATE` | `java.util.Date` | `setFieldAsDate` |
| `BIT`銆乣BOOLEAN` | `boolean` | `setFieldAsBoolean` |
| `BLOB`銆乣BINARY`銆乣VARBINARY` | `byte[]` | *锛堝師濮嬪瓧娈碉級* |

姣忓紶琛ㄧ敓鎴愪袱涓枃浠讹細

1. **Java POJO** 鈥?渚嬪 `src/main/java/custom/objects/User.java`
2. **XML 鏄犲皠** 鈥?渚嬪 `src/main/resources/custom/objects/User.map.xml`

---

## 鏈€浣冲疄璺?
1. **setter 涓繀椤昏皟鐢?`setFieldAs*`銆?* 鑻ユ湭璋冪敤锛孫RM 涓嶇煡閬撹瀛楁闇€瑕佹寔涔呭寲锛宍append()` / `update()` 灏嗛潤榛樿烦杩囪瀛楁銆?
2. **`setData()` 涓娇鐢ㄦ暟鎹簱鍒楀悕銆?* `row.getFieldInfo()` 鐨勯敭蹇呴』鏄疄闄呮暟鎹簱鍒楀悕锛坰nake_case锛夛紝鑰岄潪 Java 灞炴€у悕銆?
3. **濮嬬粓浣跨敤鍙傛暟鍖栨煡璇€?* 閫氳繃 `findWith()` 鎴?`preparedStatement()` 鐨?`Object[]` 鍙傛暟浼犻€掑€硷紝缁濅笉灏嗙敤鎴疯緭鍏ユ嫾鎺ヨ繘 SQL 瀛楃涓层€?
4. **缂撳瓨绋冲畾鐨勫弬鑰冩暟鎹€?* 浣跨敤 `Cache.getInstance()` 缂撳瓨璺ㄨ姹傚熀鏈笉鍙樼殑鏁版嵁锛堝涔︾洰鍒楄〃銆佺珷鑺傛暟閲忋€佽瑷€鍏冩暟鎹級銆?
5. **浣跨敤 `setTableName()` 澶勭悊鐗堟湰鍖栬〃銆?* 褰撲竴涓ā鍨嬪搴斿寮犵粨鏋勭浉鍚岀殑琛紙濡傚湥缁忓悇璇戞枃鐗堟湰锛夛紝閫氳繃 `setTableName()` 鍦ㄨ繍琛屾椂鍒囨崲銆?
6. **浣跨敤 `setRequestFields()` 杩涜鑱氬悎鏌ヨ銆?* 鍦ㄨ皟鐢?`findWith()` 鍓嶈鐩?SELECT 鎶曞奖锛堝 `"count(*) as n"`銆乣"max(chapter_id) as max_chapter"`锛夈€?
7. **UUID 鑷姩鐢熸垚銆?* XML 鏄犲皠涓缃?`generate="true"` 鍚庯紝`append()` 浼氳嚜鍔ㄥ啓鍏?UUID 骞跺彲閫氳繃 `getId()` 绔嬪嵆璇诲彇锛屾棤闇€鎵嬪姩璁剧疆涓婚敭銆?
8. **鐢?try-with-resources 鍖呰９ `DatabaseOperator`銆?* 鍗充娇鎶涘嚭寮傚父锛屼篃鑳界‘淇濊繛鎺ュ綊杩樿繛鎺ユ睜銆?
9. **鏄犲皠鏂囦欢璺緞椤讳笌 Java 鍖呰矾寰勪竴鑷淬€?* `custom.objects.User` 绫诲搴旂殑鏄犲皠鏂囦欢璺緞涓虹被璺緞鏍圭洰褰曚笅鐨?`custom/objects/User.map.xml`銆?
---

## 涓嬩竴姝?
- 浜嗚В[楂樼骇鐗规€(advanced-features.md)
- 鎺㈢储[鏈€浣冲疄璺礭(best-practices.md)
- 鏌ョ湅[鏁版嵁搴?API 鍙傝€僝(api/database.md)
