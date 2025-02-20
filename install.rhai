
// builds the connector from a given path (never called by the engine directly)
fn build_from_path(ctx, repo_path) {
	info("Installing connector");
	cargo("build --release --all-features", repo_path);
	ctx.copy_cargo_plugin_artifact(repo_path, name_to_lib(ctx.crate_name()));

	info("Installing memflow-kvm kernel module");
	ctx.dkms_install(repo_path);

	post_install();

	info("memflow-kvm kernel module installation finished");
	info("you might have to manually invoke 'modprobe memflow' after installation and make sure the /dev/memflow device is present.");
}

// builds the connector from local path
fn build_local(ctx) {
	build_from_path(ctx, ctx.build_path())
}

fn get_source(ctx) {
	ctx.clone_repository()
}

// builds the connector from source
fn build_from_source(ctx) {
	build_from_path(ctx, get_source(ctx))
}

// downloads a binary release of the plugin, still needs dkms
fn install(ctx) {
	let release = ctx.github_latest_release();
	let libname = name_to_lib_with_arch(ctx.crate_name());
	let artifact = download(ctx.github_release_artifact(release, libname));
	write_plugin_artifact(artifact);

	info("Installing memflow-kvm kernel module");
	let tarball = download(ctx.github_release_artifact(release, "memflow-" + release.semver() + "-source-only.dkms.tar.gz"));
	ctx.dkms_install(tarball);

	post_install();

	info("memflow-kvm kernel module installation finished");
	info("you might have to manually invoke 'modprobe memflow' after installation and make sure the /dev/memflow device is present.");
}

fn post_install() {
	try {
		udev_add_rule("memflow-kvm", "KERNEL==\"memflow\" SUBSYSTEM==\"misc\" GROUP=\"memflow\" MODE=\"0660\"");
	} catch (err) {
		info("Your memflowup installation might be out of date, please make sure to use the latest version.")
	}
}
