//
//  ContentView.swift
//  Shared
//
//  Created by Арина Нефёдова on 09.04.2021.
//

import SwiftUI
import SwiftSoup
import Darwin
struct ContentView: View {
    @State var flats = [csvScheme]()
    @State var objects = [Objects]()
    @State var totalOffers = 0
    let startID = 2206
    let number = "9643937878"
    let maxImg = 284
    let pathFilter = Bundle.main.path(forResource:"Filter2206", ofType: "csv")!
   // let pathOutput = Bundle.main.path(forResource:"outputDK", ofType: "xml")
    
    let cpi = ["Гавань капитанов", "Terra", "Эталон на Неве", "riviere noire", "Domino", "Grand House"]

    let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("flats.csv")
    var body: some View {
        Text("Hello, world!")
            .padding()
            .onAppear() {
                print(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString)
                //wixObject()
                playground()
            }
    }
    
    func playground() {
        
        guard let pathCsv = Bundle.main.path(forResource:"tb0406", ofType: "csv") else {
            fatalError("Can not1")
        }
        guard let pathJson = Bundle.main.path(forResource:"objects", ofType: "txt"),
            
              let json = try? Data(contentsOf: URL(fileURLWithPath: pathJson )) else {
            fatalError("Can not2")
        }

        
        if let encode = try? JSONDecoder().decode([Objects].self, from: json) {
        addObject(encode, compl : {


        if let aStreamReader = StreamReader(path: pathCsv) {

//            let text = ""
//            do {
//            try text.write(to: URL(fileURLWithPath: pathOutput!), atomically: false, encoding: .utf8)
//            } catch {
//                print(error)
//            }

            addTxt("""
        <?xml version="1.0" encoding="UTF-8"?>
        <realty-feed xmlns="http://webmaster.yandex.ru/schemas/feed/realty/2010-06">
        """)
            addAvitoOffer("""
<Ads formatVersion="3" target="Avito.ru">
""")

            while let line = aStreamReader.nextLine() {


                let arr = line.components(separatedBy : ";")
                if arr[0] != "id" {
                    addFlat(arr, line) { (price) in
                        
                       
                        if price == nil {
                            aStreamReader.close()

                            return
                        }

                    }




                }


            }
            filter()
            
           



        }

            })
        }
        
        
        
    }
    
    func wixObject() {
        
        
        
        guard let pathJson = Bundle.main.path(forResource:"objects2", ofType: "json"),
            
              let json = try? Data(contentsOf: URL(fileURLWithPath: pathJson )),
              let objects = try? JSONDecoder().decode([Object].self, from: json) else {
            fatalError("Can not")
        }
        addTxt("""
        "ID","Created Date","Updated Date","Owner","complex","cession","type","underground","toUnderground","address","deadline","developer","img"\n
        """)
        DispatchQueue.main.async {
        for i in objects {
            
            
            getAddress(i, compl: { addressJson in
                let line = """
            "\(UUID().uuidString)",,,"","\(i.complex)","\(i.cession)","\(i.type)","\(i.underground)","\(i.toUnderground)",\(addressJson),"\(i.deadline)","\(i.developer)","\(i.img)"\n
            """
                
             
                    
                
                addTxt(line)
                
                
                
            })
           
        }
        }
        func getAddress(_ i : Object, compl: @escaping (String) -> Void) {
      
            let keyValue : String = "AIzaSyAsGfs4rovz0-6EFUerfwiSA6OMTs2Ox-M"
            var components = URLComponents(string: "https://maps.googleapis.com/maps/api/geocode/json")!
            let key = URLQueryItem(name: "key", value: keyValue) // use your key
            let address = URLQueryItem(name: "address", value: i.address)
            components.queryItems = [key, address]

          //  DispatchQueue.main.async {
            sleep(1)
            URLSession.shared.dataTask(with: components.url!) { data, response, error in
               
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, error == nil,
                    //  let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any],
                      let resp = try? JSONDecoder().decode(Response.self, from: data!),

                      
                      let f = resp.results.first  else {
                    
                    
                    
                    do{
                        
                       let d = try JSONDecoder().decode(Response.self, from: data!)
                        if d.results.count == 0 {
                            print(i.complex + " " + i.address, String(data: data!, encoding: String.Encoding.utf8) ?? "")
                        }
                    } catch {
                        print(error)
                    }
                  //  print(String(describing: response))
                   // print(String(describing: error))
                    return
                }
                
                let coor = f.geometry.location
                let lat =  coor.lat
                let lng = coor.lng
               // DispatchQueue.main.async {
                    let str = """
        "{""city"":""Санкт-Петербург"",""location"":{""latitude"":\(lat),""longitude"":\(lng)},""streetAddress"":{""number"":"" "",""name"":"" "",""apt"":"" ""},""formatted"":""\(i.address)"",""country"":""RU""}"
        """

                compl(str)
         
            }.resume()
            

        }

        
    }
    func addFlat(_ arr: [String], _ line: String, compl : @escaping (Int?) -> Void) {
        DispatchQueue.main.async {
            
        let item = csvScheme(id: arr[0],
                         flatNumber: String(arr[1]) ,
                         district: arr[2],
                         underground: arr[3],
                         developer: arr[4],
                         complexName: arr[5],
                         deadline: arr[6],
                         section: arr[7],
                         roomType: arr[8],
                         totalS: arr[9],
                         kitchenS: arr[10],
                         repair: arr[11],
                         floor: arr[12],
                         price: arr[13],
                         
                         cession: arr[14],
                         img: arr[15],
                         room: arr[16],
                         type: arr[17],
                         toUnderground: arr[18],
                         line : line)
            
            if (Int(item.id) ?? 0) % 5000 == 0 {
                print(item.id)
            }
            if Int(item.price) ?? 0 < 25000000 {
        flats.append(item)
                compl(Int(item.price) ?? 0)
            }
                
           // compl(nil)
            
    }
    }
    
    func filter() {
        collectFilters(compl : { filters in
            
            for i in filters {
            find(i, compl : { c  in

                print(c, i.cN)
                totalOffers += c
                if let last = filters.last,
                   i == last {
                    addTxt("</realty-feed>")
                    addAvitoOffer("</Ads>")
                    print("totalOffers = ", totalOffers)
                    print(path)
                }
            })
                
            }
        })
    }
    
    func collectFilters(compl: @escaping ([Filter]) -> Void) {
        DispatchQueue.main.async {
            if let fStreamReader = StreamReader(path: pathFilter) {

//                addTxt("""
//            <?xml version="1.0" encoding="UTF-8"?>
//            <realty-feed xmlns="http://webmaster.yandex.ru/schemas/feed/realty/2010-06">
//            """)
                var filterArray = [Filter]()
                while let line = fStreamReader.nextLine() {
                    let a = line.replacingOccurrences(of: "  ", with: " ").replacingOccurrences(of: " ;", with: ";").components(separatedBy: ";")
                    
                    if a[0] != "ЖК" {
                        let item = Filter(cN: a[0],
                                          type: getType(a[2]),
                                          fromSquare: square(a[3]),
                                          fromFloor: toInt(a[4]), toPrice: toInt(a[5]),
                                          address: Array(a[7...9].map({
                                            $0.replacingOccurrences(of: "\r", with: "")
                                          })), devID: a[10])
                        filterArray.append(item)
                        print(item)
                    }
                    
                }
                compl(filterArray)
            }
            
            
        }
    }
    func square(_ square : String) -> Double? {
        if square != "" {
            return Double(Int(square) ?? 0)
        } else {
            return nil
        }
       
    }
    func toInt(_ input : String) -> Int? {
        if input != "" {
            return Int(input) ?? 0
        } else {
            return nil
        }
       
    }
    func getType(_ input : String) -> String? {
        if input != "" {
            return input
        } else {
            return nil
        }
       
    }
    func price(_ price : String) -> Int? {
        if price != "" {
            return Int(price) ?? 0
        } else {
            return nil
        }
       
    }
   
    func find(_ filter: Filter, compl : @escaping (Int) -> Void) {
        DispatchQueue.main.async {
            
           var find = flats.filter { (i) -> Bool in
                i.complexName.lowercased() == filter.cN.lowercased()
            }
            
            if find.count == 0 {
                print(filter.cN + " not found")
                compl(0)
                return
            }
            
            let totalFlats = find.sorted(by: { (Int($0.floor) ?? 0) < (Int($1.floor) ?? 0) }).map { $0.floor }.last!
           
           find = find.filter { (i) -> Bool in
            if let filterType = filter.type {
                for j in filterType.replacingOccurrences(of: " ", with: "").components(separatedBy: "+") {
                    
                    let rT : String
                    
                    switch j {

                    case "ст", "Своб. план.":
                        rT = "Студии"
                        
                    default:
                        rT = j + "-к.кв"
                    }
                    
                    if i.roomType == rT,
                       Double(i.totalS) ?? 0.0 > filter.fromSquare ?? 0.0,

                       Int(i.floor) ?? 0 > filter.fromFloor ?? 0,

                       Int(i.price) ?? 0 < filter.toPrice ?? 25000000 {
                        
                        return true
                    }
                       
                }
                return false
            } else  if Double(i.totalS) ?? 0.0 > filter.fromSquare ?? 0.0,

                        Int(i.floor) ?? 0 > filter.fromFloor ?? 0,

                        Int(i.price) ?? 0 < filter.toPrice ?? 25000000 {
                         
                         return true
                     }
                   
            
            return false
                
            }
            
            for (n, item) in find.enumerated() {
                
                guard n < 3 else {
                    return
                }
                var offer = """
            <offer internal-id="\(String(startID) + item.id)">
            <type>продажа</type>
            <property-type>жилая</property-type>
            <category>квартира</category>
            <deal-status>первичная продажа вторички</deal-status>

            <location>
              <country>Россия</country>
              
              <locality-name>Санкт-Петербург</locality-name>
              <address>\(getAddress(n, filter.address))</address>
              <apartment>\(item.flatNumber)</apartment>
              <metro>
                      <name>\(item.underground)</name>
                        <time-on-\(item.toUnderground.contains("транспортом") ? "transport" : "foot")>\(item.toUnderground.replacingOccurrences(of: "мин", with: "").replacingOccurrences(of: "пешком", with: "").replacingOccurrences(of: "транспортом", with: "").replacingOccurrences(of: " ", with: "")
                        )</time-on-\(item.toUnderground.contains("транспортом") ? "transport" : "foot")>

                      
              </metro>
            </location>
            <sales-agent>
            <category>agency</category>
              <phone>\(number)</phone>
            </sales-agent>
            \(getImages(Int(item.id) ?? 0, item))
            <price>
              <value>\(item.price)</value>
              <currency>RUR</currency>
            </price>
              \(item.type == "Апартаменты" ? "<apartments>1</apartments>" : "")
            <area>
              <value>\(item.totalS)</value>
              <unit>кв. м</unit>
            </area>
            <kitchen-space>
                <value>\(item.kitchenS)</value>
                <unit>кв. м</unit>
            </kitchen-space>
            <building-section>\(item.section)</building-section>
            <mortgage>1</mortgage>
            <lift>1</lift>
            <parking>1</parking>
            <security>1</security>
            <ceiling-height>3</ceiling-height>
            <guarded-building>true</guarded-building>
            <description>
            \(getDesc(item))
            </description>
            """
                        
                        if item.roomType.contains("Студии") {
                        offer.append("""
                <rooms>студия</rooms>
                """)
                        }
                        if item.roomType.contains("Своб. план.") {
                        offer.append("""
                <open-plan>1</open-plan>
                """)
                        }

                        if item.roomType.contains("1-к") {
                        offer.append("""
                <rooms>1</rooms>
                """)
                        }
                        if item.roomType.contains("2Е-к") {
                        offer.append("""
                <rooms>2</rooms>
                """)
                        }
                        if item.roomType.contains("2-к") {
                        offer.append("""
                <rooms>2</rooms>
                """)
                        }
                        if item.roomType.contains("3Е-к") {
                        offer.append("""
                <rooms>3</rooms>
                """)
                        }
                        if item.roomType.contains("3-к") {
                        offer.append("""
                <rooms>3</rooms>
                """)
                        }
                        if item.roomType.contains("4Е-к") {
                        offer.append("""
                <rooms>4</rooms>
                """)
                        }
                        if item.roomType.contains("4-к") {
                        offer.append("""
                <rooms>4</rooms>
                """)
                        }
                        if item.roomType.contains("5Е-к") {
                        offer.append("""
                <rooms>5</rooms>
                """)
                        }
                        
                        if item.roomType.contains("5-к") {
                        offer.append("""
                <rooms>5</rooms>
                """)
                        }
                        
                        
                    
                    offer.append("""
            <floor>\(item.floor)</floor>
            <floors-total>\(totalFlats)</floors-total>
            </offer>
            """)
                
                
                
                
                var avitoOffer = """
        <Ad>
        <Id>\(String(startID) + (cpi.map({$0.lowercased()}).contains(where: filter.cN.lowercased().contains) ? "2306" : "") + item.id)</Id>
        <Category>Квартиры</Category>
        <OperationType>Продам</OperationType>
        <DateBegin>2021-04-10</DateBegin>
        <DateEnd>2079-08-28</DateEnd>
        <Description><![CDATA[
            Новая, просторная, светлая и уютная квартира с типовым косметическим ремонтом в новом доме.<br /><br />

            \(getDesc(item))<br /><br />

            А также:<br />
                * стеклопакеты,<br />
                * паркетная доска,<br />
                * прямая продажа.<br />
        ]]></Description>
        <Address>Россия, Санкт-Петербург, \(getAddress(n, filter.address))</Address>
        <PropertyRights>Посредник</PropertyRights>
        <Price>\(item.price)</Price>
        <CompanyName>АН 78</CompanyName>
        <ManagerName>Артем Казьмирчук</ManagerName>
        <AllowEmail>Нет</AllowEmail>
            \(getImagesAvito(Int(item.id) ?? 0, item))
        """
       
                               if item.roomType.contains("Студии") {
                                avitoOffer.append("""
                       <Rooms>Студия</Rooms>
                       """)
                               }
                               if item.roomType.contains("Своб. план.") {
                                avitoOffer.append("""
                       <Rooms>Своб. планировка</Rooms>
                       """)
                               }

                               if item.roomType.contains("1-к") {
                                avitoOffer.append("""
                       <Rooms>1</Rooms>
                       """)
                               }
                               if item.roomType.contains("2Е-к") {
                                avitoOffer.append("""
                       <Rooms>2</Rooms>
                       """)
                               }
                               if item.roomType.contains("2-к") {
                                avitoOffer.append("""
                       <Rooms>2</Rooms>
                       """)
                               }
                               if item.roomType.contains("3Е-к") {
                                avitoOffer.append("""
                       <Rooms>3</Rooms>
                       """)
                               }
                               if item.roomType.contains("3-к") {
                                avitoOffer.append("""
                       <Rooms>3</Rooms>
                       """)
                               }
                               if item.roomType.contains("4Е-к") {
                                avitoOffer.append("""
                       <Rooms>4</Rooms>
                       """)
                               }
                               if item.roomType.contains("4-к") {
                                avitoOffer.append("""
                       <Rooms>4</Rooms>
                       """)
                               }
                               if item.roomType.contains("5Е-к") {
                                avitoOffer.append("""
                       <Rooms>5</Rooms>
                       """)
                               }
                               
                               if item.roomType.contains("5-к") {
                                avitoOffer.append("""
                       <Rooms>5</Rooms>
                       """)
                               }
                               
                avitoOffer += """
        <Square>\(item.totalS)</Square>
        <Floor>\(item.floor)</Floor>
        <Floors>\(totalFlats)</Floors>
        <HouseType>Монолитный</HouseType>
        <MarketType>\(cpi.map({$0.lowercased()}).contains(where: filter.cN.lowercased().contains) ? "Вторичка" : "Новостройка")</MarketType>
        \(cpi.map({$0.lowercased()}).contains(where: filter.cN.lowercased().contains) ? "<NewDevelopmentId>" + filter.devID + "</NewDevelopmentId>" : "")

        \(cpi.map({$0.lowercased()}).contains(where: filter.cN.lowercased().contains) ? "<Decoration>Чистовая</Decoration>" : "")

        <Status>Квартира</Status>
        <BalconyOrLoggia>Лоджия</BalconyOrLoggia>
        <ViewFromWindows>
            <Option>На улицу</Option>
            <Option>Во двор</Option>
        </ViewFromWindows>
    </Ad>
"""
                
                
                if cpi.map({$0.lowercased()}).contains(where: filter.cN.lowercased().contains) {
                    addAvitoOfferSecond(avitoOffer)
                }
                addAvitoOffer(avitoOffer)
                
                addTxt(offer)
                
                addCsv(item, getAddress(n, filter.address))
                
            }
            compl(find.count < 5 ? find.count : 5)
        }
        
        //compl()
    }
    
    
    func addObject(_ arr: [Objects], compl : @escaping () -> Void) {
        DispatchQueue.main.async {
            objects.append(contentsOf: arr)
            compl()
        }
    }
    func getAddress(_ id: Int, _ address: [String]) ->String {
        
        var loc = address[0]
        
        
        if (id % 3) == 0 {
            loc = address[1]
        } else if (id % 5) == 0 {
            loc = address[2]
            
        }

        return loc
    }
    func getImages(_ n: Int, _ i : csvScheme) -> String {
            
               let img = """
            <image>http://agency78.spb.ru/imgC/\(String((n % maxImg) + 1) + "c.png")</image>
            <image>\(i.img.replacingOccurrences(of: "https", with: "http"))</image>
            <image>\(objects.filter({obj in
                obj.complex == i.complexName
            })[0].img.replacingOccurrences(of: "https", with: "http"))</image>

            """
     
        return img
    }
    
    func getImagesAvito(_ n: Int, _ i : csvScheme) -> String {
            
               let img = """
                    <Images>
                        <Image url="\(i.img.replacingOccurrences(of: "https", with: "http"))" />
                        <Image url="http://agency78.spb.ru/imgC/\(String((n % maxImg) + 1) + "c.png")" />
                        <Image url="\(objects.filter({obj in
                obj.complex == i.complexName
            })[0].img.replacingOccurrences(of: "https", with: "http"))" />
            </Images>
            """
     
        return img
    }
    
    func getDesc(_ item : csvScheme) -> String {
       
        
        var desc = """
     Замечательная \(checkRoomType(item)) на \(item.floor) этаже в историческом \(item.district.replacingOccurrences(of: "ий р-н", with: "ом")) районе Санкт-Петербурга.<br /><br />

     До метро \(item.underground + " " + item.toUnderground)<br /><br />
     """
        if item.kitchenS != "0.0" {
            desc += "\n Площадь кухни – " + item.kitchenS + "м²<br /><br />"
        }
        if !item.repair.contains("отделки") {
            switch item.repair {
            case "Подчистовая", "Чистовая":
                desc += "\n" + item.repair + " отделка"
            case "С мебелью":
                desc += "\n" + item.repair
            default: break
                
            }
           
        }
        if item.deadline == "Сдан" {
            desc += "\n" + "Готовая квартира в СДАННОМ доме"
        }
        let footer = """

            В пешей доступности находятся детские сады, школы, гимназии, лицеи и вузы, работают торговые центры, магазины, спортивные центры, кафе и рестораны.<br /><br />

            ПОЗВОНИВ к нам в офис, вы сэкономите время на поиск необходимой вам квартиры.<br /><br />
            
            Предложения во всех новостройках города!<br />
            """
        return desc + footer
        
    }
    
    func checkRoomType(_ item: csvScheme) -> String {

        if item.roomType == "Своб. план." {
            
            return "квартира СВОБОДНОЙ планировки"
        } else if item.roomType == "Студии" {
            return "студия"
        } else {
            return item.roomType.replacingOccurrences(of: "кв", with: "") + " квартира"
        }
    }
    
    func addTxt(_ s : String) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let path = documentsPath.appendingPathComponent("outputDK.xml")
        do {
            let fileUpdater = try FileHandle(forUpdating: URL(fileURLWithPath: path))
            // Function which when called will cause all updates to start from end of the file
            
            fileUpdater.seekToEndOfFile()
            
            // Which lets the caller move editing to any position within the file by supplying an offset
            fileUpdater.write(s.data(using: .utf8)!)

            // Once we convert our new content to data and write it, we close the file and that’s it!
            fileUpdater.closeFile()
        } catch {
            print(error)
        }
    }
    func addAvitoOfferSecond(_ s : String) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let path = documentsPath.appendingPathComponent("outputAvitoSecond.xml")
        do {
            let fileUpdater = try FileHandle(forUpdating: URL(fileURLWithPath: path))
            // Function which when called will cause all updates to start from end of the file
            
            fileUpdater.seekToEndOfFile()
            
            // Which lets the caller move editing to any position within the file by supplying an offset
            fileUpdater.write(s.data(using: .utf8)!)

            // Once we convert our new content to data and write it, we close the file and that’s it!
            fileUpdater.closeFile()
        } catch {
            print(error)
        }
    }
    func addAvitoOffer(_ s : String) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let path = documentsPath.appendingPathComponent("outputAvito.xml")
        do {
            let fileUpdater = try FileHandle(forUpdating: URL(fileURLWithPath: path))
            // Function which when called will cause all updates to start from end of the file
            
            fileUpdater.seekToEndOfFile()
            
            // Which lets the caller move editing to any position within the file by supplying an offset
            fileUpdater.write(s.data(using: .utf8)!)

            // Once we convert our new content to data and write it, we close the file and that’s it!
            fileUpdater.closeFile()
        } catch {
            print(error)
        }
    }
    func addCsv(_ foundedFlat : csvScheme, _ address : String) {
        
    
        
       
        do {
            let fileUpdater = try FileHandle(forUpdating: URL(fileURLWithPath: path))
            // Function which when called will cause all updates to start from end of the file
            
            fileUpdater.seekToEndOfFile()
            
            // Which lets the caller move editing to any position within the file by supplying an offset
           
            fileUpdater.write((foundedFlat.line.replacingOccurrences(of: "\r", with: "") + ";" + address + "\n").data(using: .utf8)!)

            // Once we convert our new content to data and write it, we close the file and that’s it!
            fileUpdater.closeFile()
        } catch {
            print(error)
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


class StreamReader  {

    let encoding : UInt
    let chunkSize : Int

    var fileHandle : FileHandle!
    let buffer : NSMutableData!
    let delimData : NSData!
    var atEof : Bool = false

    init?(path: String, delimiter: String = "\n", encoding : UInt = String.Encoding.utf8.rawValue, chunkSize : Int = 4096) {
        self.chunkSize = chunkSize
        self.encoding = encoding

        if let fileHandle = FileHandle(forReadingAtPath: path),
           let delimData = delimiter.data(using: String.Encoding(rawValue: encoding)),
           let buffer = NSMutableData(capacity: chunkSize)
        {
            self.fileHandle = fileHandle
            self.delimData = delimData as NSData
            self.buffer = buffer
        } else {
            self.fileHandle = nil
            self.delimData = nil
            self.buffer = nil
            return nil
        }
    }

    deinit {
        self.close()
    }

    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        precondition(fileHandle != nil, "Attempt to read from closed file")

        if atEof {
            return nil
        }

        // Read data chunks from file until a line delimiter is found:
        var range = buffer.range(of: delimData as Data, options: [], in: NSMakeRange(0, buffer.length))
        while range.location == NSNotFound {
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.count == 0 {
                // EOF or read error.
                atEof = true
                if buffer.length > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = NSString(data: buffer as Data, encoding: encoding)

                    buffer.length = 0
                    return line as String?
                }
                // No more lines.
                return nil
            }
            buffer.append(tmpData)
            range = buffer.range(of: delimData as Data, options: [], in: NSMakeRange(0, buffer.length))
        }

        // Convert complete line (excluding the delimiter) to a string:
        let line = NSString(data: buffer.subdata(with: NSMakeRange(0, range.location)),
            encoding: encoding)
        // Remove line (and the delimiter) from the buffer:
        buffer.replaceBytes(in: NSMakeRange(0, range.location + range.length), withBytes: nil, length: 0)

        return line as String?
    }

    /// Start reading from the beginning of file.
    func rewind() -> Void {
        fileHandle.seek(toFileOffset: 0)
        buffer.length = 0
        atEof = false
    }

    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}



struct csvScheme {
   
    var id : String
    var flatNumber : String
    var district : String
    var underground : String
    var developer : String
    var complexName : String
    var deadline : String
    var section : String
    var roomType : String
    var totalS : String
    var kitchenS : String
    var repair : String
    var floor : String
    var price : String
    var cession : String
    var img : String
    var room : String
    var type : String
    var toUnderground : String
    var line : String
}

struct Filter : Equatable{
    var cN : String
    var type : String?
    var fromSquare : Double?
    var fromFloor : Int?
    var toPrice : Int?
    var address : [String]
    var devID : String
}
extension String {

    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

struct Objects : Decodable {
    
  //  var id : Int
    var img : String
    var complex : String
//    var cession : String
//    var type : String
//    var underground : String
//    var toUnderground : String
//    var address : String
//    var deadline : String
//    var developer : String
}
struct Object : Identifiable, Decodable {
    var id : Int
    var img : String

    var complex : String
    var cession : String

    var type : String

    var underground : String

    var toUnderground : String
    var address : String
    var deadline : String
    var developer : String
}

struct Response  : Decodable{
    var results : [Results]
    struct Results : Decodable {
        var geometry : Loc
    }
    struct Loc : Decodable{
        var location : geo
        
    }
    struct geo : Decodable{
        var lat : Double
        var lng : Double
    }
}
