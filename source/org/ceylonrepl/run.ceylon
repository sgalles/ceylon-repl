import ceylon.file {
    Path,
    Nil,
    File,
    parsePath
}

class VFile(shared String name, shared String text){}
class VDir(shared String name, shared {VNode*} children){}
alias VNode => VFile|VDir;
void createTree(Path parentDir, {VNode*} children){
    for(node in children){
        switch(node)
        case(is VDir){ 
            createTree(parentDir.childPath(node.name), node.children);
        }
        case(is VFile){ 
            assert(is File file = 
                let(resource = parentDir.childPath(node.name).resource)
                if(is Nil resource) then resource.createFile(true) else resource
            );
            try (writer = file.Overwriter()) {
                writer.write(node.text);
            }
        }
    }
}

VDir replTemplate() 
 => VDir {name = "source";
        VDir{name = "generatedrepl";
            VFile(
                "module.ceylon",
                """module repl "1.0.0" { import ceylon.file "1.1.1";}"""
            ),
            VFile(
                "package.ceylon",
                """shared package repl;"""
            )
        }
};  

"Run the module `org.ceylonrepl`."
shared void run() {
    
    createTree(parsePath("C:/work/test"), {replTemplate()});
         
    
}
    

    

    
