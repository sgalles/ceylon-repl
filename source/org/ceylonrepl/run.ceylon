import ceylon.collection {
    HashMap
}
import ceylon.file {
    Path,
    Nil,
    File,
    parsePath,
    Reader
}
import ceylon.interop.java {
    javaString
}
import ceylon.process {
    createProcess,
    Process,
    currentOutput,
    currentError
}

import java.util.regex {
    Pattern
}



"Run the module `org.ceylonrepl`."
shared void run() {
    
    
    value projectPath = parsePath("C:/work/test");
    
    Boolean ceylonCommand(String command){
        String ext = if(Path.separator == "/") then "sh" else "bat";
        Process p = createProcess { 
            command = "ceylon.``ext``";
            arguments = command.split();                                            
            path = projectPath;
            //output = currentOutput;
            error = currentError;
        };
        if (is Reader reader = p.output) {
            while (exists line = reader.readLine()) {
                if(line.startsWith("@@@")){
                    print(line);
                }
                
            }
        }
        return p.waitForExit() == 0;
    }
    
    void createFiles({FileContent*} filesContent){
        for(fc in filesContent){
            assert(is File file = 
                let(resource = projectPath.childPath("source").childPath(generatedModuleName).childPath(fc.name).resource)
                if(is Nil resource) then resource.createFile(true) else resource
            );
            try (writer = file.Overwriter()) {
                fc.lines.collect((t) => switch(t) case(is String) [t] case(is String[]) t)
                        .flatMap(identity)
                        .each(writer.writeLine);
            }
        }
    }
    
    value decl = HashMap<String, String>();
    String withPrint(String s) => "print(\"@@@\".plus((``s``).string));";
    while(true){
        print("command ?");
        if(exists line = process.readLine()){
            value identifierMatcher = identifierRe.matcher(javaString(line));
            value [
                trailingLines,
                commit,
                String? newVariableName] =   
                             if(identifierMatcher.matches()) 
                             then let(variableName = identifierMatcher.group(1),variableDeclaration = "value ``line``;") [
                                    [variableDeclaration, withPrint(variableName)],
                                    void(){decl.put(variableName, variableDeclaration);},
                                    variableName
                             ]
                             else [
                                let(expression = line) [withPrint(expression)],
                                void(){},
                                null
                             ];
                
                
            String[] lines = [for (k->v in decl) 
                             if(if(exists newVariableName) then k != newVariableName else true) v
                ].append(trailingLines);   
            createFiles(replTemplate(lines));
            if(ceylonCommand("compile")){
                commit();
                ceylonCommand("run ``generatedModuleName``/1.0.0");
            }
        }
    }
}
    
    
String generatedModuleName = "generatedrepl";
    
class FileContent(shared String name, shared {<String|String[]>*} lines){}
    
[FileContent+] replTemplate(String[] runLines) 
            => [
    FileContent{
        name = "module.ceylon";
        "module ``generatedModuleName`` \"1.0.0\" { import ceylon.file \"1.1.1\";}"
    },
    FileContent{
        name = "package.ceylon";
        "shared package ``generatedModuleName``;"
    },
    FileContent{
        name = "run.ceylon";
        """import ceylon.file { ...}""",
        "shared void run(){",
        runLines,
        "}"
    }
];
    
Pattern identifierRe = Pattern.compile("""^\s*(\w+)\s*=[^=]+""");
    

    

    
