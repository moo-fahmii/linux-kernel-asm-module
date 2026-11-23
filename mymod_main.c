#include <linux/module.h>
#include <linux/kernel.h>

extern int my_asm_init(void);
extern void my_asm_exit(void);

static int __init mymod_init(void){
    return my_asm_init();
}

static void __exit mymod_exit(void){
     my_asm_exit();
}

module_init(mymod_init);
module_exit(mymod_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Mohamed");
MODULE_DESCRIPTION("Minimal kernel module with assembly logic");
MODULE_VERSION("0.1");
