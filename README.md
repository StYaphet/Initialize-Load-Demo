#initialize方法与load方法的区别
最近在读《Objective-C程序设计》的时候，看到了书中说：
>程序开始执行时，它向所有的类发送initialize调用方法。该消息只向某个类发送一次，并且在向该类发送其他消息之前。如果存在一个类及其相关的子类，则父类首先得到这条消息。

想想自己从来都是从别人的博客或者其他文章中看到有关类的`initialize`方法与`load`方法的区别，自己则没有深刻的体会，于是今天晚上我写了一个小的demo来测试一下`initialize`方法与`load`方法的区别到底有什么区别，加深一下自己对这两个方法的理解。

##准备工作
因为自己平时写demo或者是工作中编写的项目都是iOS系统的项目，因此我轻车熟路的创建了一个iOS的single View Application，工程创建完毕，XCode自动为我们创建了两个类，一个是程序代理AppDelegate类，一个是ViewController类，因为我不喜欢ViewController这个类的命名，一个ViewController不指定一个具体的名称，就不知道它可能会用到那些地方，所以我总是会把这个文件给删除掉，delete -> move to trash,目前为止一切完美。接下来我们创建一个自定义的ViewController类，起名叫做CustomViewController。
##测试initialize方法
测试`initialize`方法，我们在AppDelegate类与自定义的CustomViewController类中都添加如下的代码：

	+ (void)initialize {
    	NSLog(@"-------initialize-------%@",NSStringFromClass([self class]));
	}

command+R运行，发现在控制台输出了如下的信息
	
	2016-07-30 23:20:03.533 InitializeVSLoad[10664:7768911] -------initialize-------AppDelegate
	2016-07-30 23:20:03.535 InitializeVSLoad[10664:7768911] -------initialize-------CustomViewController
	
此时我们未向该demo项目中添加任何代码，完全是自动生成的代码，这样就验证了《Objective-C程序设计》一书中所说的：程序开始执行时，向所有的类发送`initialize`调用方法。
##测试initialize方法执行次数
向项目中添加一个CustomViewController的分类：CustomViewController+Test,并在该分类的实现文件中添加代码：

	+ (void)initialize {
    	NSLog(@"-------initialize-------%@",NSStringFromClass([self class]));
	}
	
构建运行，发现控制台输出与刚才别无二致，所以，initialize方法真是是对于每一个类只执行一次，且程序在开始执行时即向所有的类发送`initialize`方法调用（为了验证是否是对所有的类发送`initialize`方法调用，我偷偷测试了一个叫做CustomView的View子类，发现CustomView的`initialize`方法同样也被调用了，掩面~）
##测试load方法
向所有类的实现文件中添加如下的代码：

	+ (void)load {
   	 	NSLog(@"-------load-------%@",NSStringFromClass([self class]));
	}
	
在CustomViewController的Test分类中添加如下的代码：
	
	+ (void)load {
   	 	NSLog(@"-------load：Test-------%@",NSStringFromClass([self class]));
	}
	
再次构建运行，发现控制台的输出如下：

	2016-07-30 23:42:18.524 InitializeVSLoad[10714:7783586] -------initialize-------AppDelegate
	2016-07-30 23:42:18.525 InitializeVSLoad[10714:7783586] -------load-------AppDelegate
	2016-07-30 23:42:18.525 InitializeVSLoad[10714:7783586] -------initialize-------CustomView
	2016-07-30 23:42:18.525 InitializeVSLoad[10714:7783586] -------load-------CustomView
	2016-07-30 23:42:18.526 InitializeVSLoad[10714:7783586] -------initialize-------CustomViewController
	2016-07-30 23:42:18.526 InitializeVSLoad[10714:7783586] -------load-------CustomViewController
	2016-07-30 23:42:18.526 InitializeVSLoad[10714:7783586] -------load：Test-------CustomViewController
	2016-07-30 23:42:18.607 InitializeVSLoad[10714:7783586] Unknown class ViewController in Interface Builder file.
	2016-07-30 23:42:18.610 InitializeVSLoad[10714:7783586] -----方法：application:didFinishLaunchingWithOptions:-------
	
这时我们可以发现，`load`方法总是在`initialize`方法之后才会被调用，而且分类中的`load`方法同样也被调用了，这一切都发生在AppDelegate类的`application:didFinishLaunchingWithOptions:`被调用之前。

##查看函数调用栈分析实际方法调用情况

在上面控制台的输出中，我们认为`load`方法总是在`initialize`方法之后才会被调用，但当我对AppDelegate类的`initialize`方法和`load`方法分别打断点查看其函数调用栈信息发现其实实际情况是这样的：

* 其实系统会在线程上首先发送`call_load_method`，这会使系统向所有的类发送`load`方法调用，对于AppDelegate类，它会收到[AppDelegate load]，但是`load`方法内的代码还不真正执行
* 继续往下执行，线程上会调用运行时的`objc_msgSend`方法、`_class_intialize`方法
* 接下来，AppDelegate类的`initialize`方法才会被调用

我对这个过程的理解是这样的：

* 首先系统向所有的类发送`load`方法调用：`call_load_method`
* 接着每个类都会收到`[XXXClass load]`
* 在`load`方法里，系统先跳转到类的`initialize`方法对类进行初始化（感觉像是在`load`方法里默认调用本类的`initialize`方法，只不过是通过runtime的`_class_intialize`来做的）
* 初始化完成之后，继续返回执行`load`方法中剩下的代码

那么对于分类呢？分类的`load`方法是不是也会调用本类的`initialize`方法呢？从结果中看分类的`load`方法并没有调用`initialize`方法，我们在函数调用栈中会发现什么呢？

对CustomViewController的Test分类的`initialize`方法和`load`方法分别打断点查看其函数调用栈信息,在函数调用栈中并没有发现`objc_msgSend`方法、`_class_intialize`方法，分类中的`load`方法的代码直接执行，猜测是类中有一个静态变量flag，一旦`initialize`方法调用过一次之后就设置flag为某个值（true），之后根据这个flag值来决定`initialize`方法执行不执行。

*注意*CustomViewController的Test分类的同样也收到了`call_load_method`消息

等有时间学习一些如何查看项目的C++源码，应该还会有新的知识可以学到。