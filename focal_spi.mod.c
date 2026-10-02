#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};


MODULE_INFO(depends, "");

MODULE_ALIAS("acpi*:FTE3600:*");
MODULE_ALIAS("acpi*:FTE4800:*");
MODULE_ALIAS("acpi*:FTE6600:*");
MODULE_ALIAS("acpi*:FTE6900:*");

MODULE_INFO(srcversion, "05217E3F8A353CE7520D282");
