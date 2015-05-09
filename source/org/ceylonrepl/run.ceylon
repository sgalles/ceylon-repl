import ceylon.collection {
    HashMap
}
import ceylon.file {
    Path,
    Nil,
    File,
    parsePath
}
import ceylon.process {
    createProcess,
    Process,
    currentOutput,
    currentError
}


class FileContent(shared String name, shared {<String|String[]>*} lines){}
void createFiles(Path dir)({FileContent*} filesContent){
    for(fc in filesContent){
        assert(is File file = 
            let(resource = dir.childPath(fc.name).resource)
            if(is Nil resource) then resource.createFile(true) else resource
        );
        try (writer = file.Overwriter()) {
            fc.lines.collect((t) => switch(t) case(is String) [t] case(is String[]) t)
                    .flatMap(identity)
                    .each(writer.writeLine);
        }
    }
}

String generatedModuleName = "generatedrepl";

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

Boolean ceylonCommand(String command, Path projectPath){
    Process p = createProcess { 
        command = "ceylon.bat";
        arguments = command.split();                                            
        path = projectPath;
        output = currentOutput;
        error = currentError;
    };
    return p.waitForExit() == 0;
}

"Run the module `org.ceylonrepl`."
shared void run() {
    
    value varPerName = HashMap<String, String>();
    value projectPath = parsePath("C:/work/test");
    value createProjectFiles = createFiles(projectPath.childPath("source/generatedrepl"));
    while(true){
        print("command ?");
        if(exists line = process.readLine()){
            createProjectFiles(replTemplate(["``line``;"]));
            if(ceylonCommand("compile",projectPath)){
                ceylonCommand("run ``generatedModuleName``/1.0.0",projectPath);
            }
            
            

        }
    }
    
    
    //
    //

}
    

    

    
