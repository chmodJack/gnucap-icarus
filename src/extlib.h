/*$Id$ 
 * Copyright (C) 2009 Kevin Cameron
 * Authors: Kevin Cameron 
 *
 * This file is a part of plugin "Gnucap-Icarus" to "Gnucap", 
 * the Gnu Circuit Analysis Package
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 *------------------------------------------------------------------
 * Dynamic binding of PWL signal sources to external simulators 
 */

#include "vpi_priv.h"
#include "extpwl.h"
#include "e_compon.h"
#include "e_elemnt.h" 

class ExtBase {
 public:
  virtual int id() {return 0;}
  static void null_call() {}
};

class ExtAPI : public SpcDllData {
 public:

  double  *(*bindnet)(const char *,char,int *,void *,void (*)(void *,void *,double));
  double   (*startsim)(const char *,SpcDllData *);
  void     (*endsim)(double);
  double   (*contsim)(const char *,double);
  int      (*so_main)(int ,const char**);

  ExtAPI() : SpcDllData((typeof(activate))ExtBase::null_call) {
    startsim = (typeof(startsim))ExtBase::null_call;
    endsim   = (typeof(endsim))ExtBase::null_call;
    bindnet  = (typeof(bindnet))ExtBase::null_call;
    contsim  = (typeof(contsim))ExtBase::null_call;
    activate = (typeof(activate))ExtBase::null_call;
    so_main  = (typeof(so_main))ExtBase::null_call;
  }
};

class ExtLib : public ExtAPI , public COMPONENT {
 public:

  std::list<class ExtRef*> refs;

  std::string name;
  void *handle;
  double now;

  ExtLib(const char *_nm,void *_hndl) : name(_nm), handle(_hndl), now(-1) {}
  void init(const char *);

  static void SetActive(void *dl,void *handle,double time);
  void        set_active(void *handle,double time);

  virtual std::string value_name() const {return name;}
  virtual bool print_type_in_spice() const {return false;}

  static ExtLib *Sdd2El(SpcDllData *spd) {
    intptr_t p = (intptr_t)spd;
    p -= offsetof(ExtLib,active);
    return (ExtLib *)p;
  }

 private:
  ExtLib();

 public:
  virtual std::string port_name(int)const {return "";}
};

class ExtSig : public ExtBase {
 public:
# define EXT_SIG 2
  virtual int id() {return EXT_SIG;}

  COMMON_COMPONENT *cmpnt;

  ExtLib       *lib;
  SpcIvlCB     *cb_data;
  int           slots;
  char          iv;
  ELEMENT      *d;

  void set_active(double time);
  static void SetActive(void *,void *,double);

  ExtSig(COMMON_COMPONENT *_c,ExtLib *_l,char _iv,void *cbd) 
    : cmpnt(_c), lib(_l), iv(_iv), cb_data((SpcIvlCB *)cbd) {}

 private:
  ExtSig();

};

class ExtRef : public ExtBase {
 public:
# define EXT_REF 1
  virtual int id() {return EXT_REF;}

  std::list<ExtSig*> sigs;

  ExtLib       *lib;
  std::string   spec;
  char          iv;

  ExtRef(ExtLib *_l,const char *sig_spec,char _iv) 
    : lib(_l), spec(sig_spec), iv(_iv) {
    lib->refs.push_back(this);
  }
};

ExtRef *bindExtSigInit(const string &,const char *);
ExtSig *bindExtSigConnect(intptr_t,const string &,
                          const CARD_LIST* Scope,COMMON_COMPONENT *);
void    ExtSigTrEval(intptr_t,std::vector<DPAIR>*,ELEMENT*);
double  ExtSigTrCheck(intptr_t,double,std::vector<DPAIR>*,COMPONENT*);

void ExtStartSim(const char *);
void ExtContSim(const char *,double);
void ExtEndSim(double);
