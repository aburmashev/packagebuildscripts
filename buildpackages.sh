#!/bin/sh

mkdir -p ERROR_LOGS
mkdir -p SUCCESS_LOGS
for arch in `cat archs`
do
mkdir -p rebuild_repo/$arch/SRPMS
mkdir -p rebuild_repo/$arch/RPMS
umount -lf repos5/sys                                                                                                                                                                                              
umount -lf repos5/proc                                                                                                                                                                                             
umount -lf repos5/dev
rm -rf repos5.bak
rm -rf repos5

###CREATING INITIAL CHROOT#####
sudo urpmi.addmedia --urpmi-root repos5 myrepos1 /nfs/repos/mandriva/official/2011/$arch/media/main/release                                                                                                  
sudo urpmi.addmedia --urpmi-root repos5 myrepos2 /nfs/repos/mandriva/official/2011/$arch/media/contrib/release                                                                                               
sudo urpmi.addmedia --urpmi-root repos5 myrepos3 /nfs/repos/mandriva/official/2011/$arch/media/non-free/release                                                                                              
sudo urpmi  --no-suggests --excludedocs --no-verify-rpm --auto --root repos5 --urpmi-root repos5 shadow-utils rpm tar basesystem-minimal rpm-build rpm-mandriva-setup urpmi rsync bzip2 shadow-utils locales-en kernel-desktop-latest
cp -R repos5 repos5.bak

##### FINISH#####

for file in `cat src.rpms.txt`
do
umount -lf repos5/sys
umount -lf repos5/proc
umount -lf repos5/dev
rm -rf repos5
cp -R repos5.bak repos5

sudo urpmi.addmedia --urpmi-root repos5 myrepos1 /nfs/repos/mandriva/official/2011/$arch/media/main/release
sudo urpmi.addmedia --urpmi-root repos5 myrepos2 /nfs/repos/mandriva/official/2011/$arch/media/contrib/release
sudo urpmi.addmedia --urpmi-root repos5 myrepos3 /nfs/repos/mandriva/official/2011/$arch/media/non-free/release
sudo urpmi  --no-suggests --excludedocs --no-verify-rpm --auto --root repos5 --urpmi-root repos5 shadow-utils rpm tar basesystem-minimal rpm-build rpm-mandriva-setup urpmi rsync bzip2 shadow-utils locales-en
sudo urpmi  --noclean --no-suggests --excludedocs --no-verify-rpm --auto --root repos5 --urpmi-root repos5 SRPMS/$file
sudo cp SRPMS/$file repos5/$file
sudo chroot repos5 /bin/rpm --nodeps -i $file
mkdir -p repos5/dev
mkdir -p repos5/sys
mkdir -p repos5/proc
mount /proc repos5/proc
mount /sys repos5/sys
mount /dev repos5/dev
sudo chroot repos5 rpmbuild -ba /root/rpmbuild/SPECS/`chroot repos5 ls /root/rpmbuild/SPECS` --target=$arch | tee repos5/`chroot repos5 ls /root/rpmbuild/SPECS`.log 2>&1
if [ `ls repos5/root/rpmbuild/SRPMS |grep -c $file` == 0 ]; then
                echo $file >> ERROR_LOGS/error.log
                mv repos5/*.log ERROR_LOGS/
fi
cp repos5/`chroot repos5 ls /root/rpmbuild/SPECS`.log SUCCESS_LOGS
cp repos5/root/rpmbuild/RPMS/noarch/* rebuild_repo/$arch/RPMS
cp repos5/root/rpmbuild/RPMS/$arch/* rebuild_repo/$arch/RPMS/
cp repos5/root/rpmbuild/SRPMS/* rebuild_repo/$arch/SRPMS
done
done